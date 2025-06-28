---@file core/performance_settings.lua
---@brief パフォーマンス設定管理
---@details 解像度調整、フレームレート制限、品質設定などの最適化オプション

---@class PerformanceSettings
---@field targetFps number 目標FPS
---@field resolutionScale number 解像度スケール（0.1-1.0）
---@field enableVSync boolean VSync有効フラグ
---@field lowQualityMode boolean 低品質モード
---@field adaptiveQuality boolean 適応品質調整
---@field maxFrameTime number 最大フレーム時間（ms）
---@field autoOptimize boolean 自動最適化
---@field performanceTarget string パフォーマンス目標（"quality", "balanced", "performance"）
local PerformanceSettings = {}
PerformanceSettings.__index = PerformanceSettings

---@brief PerformanceSettingsコンストラクタ
---@return PerformanceSettings
function PerformanceSettings.new()
    local self = setmetatable({}, PerformanceSettings)
    self.targetFps = 60
    self.resolutionScale = 1.0
    self.enableVSync = true
    self.lowQualityMode = false
    self.adaptiveQuality = false
    self.maxFrameTime = 16.67  -- 60FPS相当
    self.autoOptimize = false
    self.performanceTarget = "balanced"
    return self
end

---@brief 目標FPS設定
---@param fps number 目標FPS
function PerformanceSettings:setTargetFps(fps)
    self.targetFps = math.max(30, math.min(120, fps))
    self.maxFrameTime = 1000 / self.targetFps
end

---@brief 解像度スケール設定
---@param scale number 解像度スケール（0.1-1.0）
function PerformanceSettings:setResolutionScale(scale)
    self.resolutionScale = math.max(0.1, math.min(1.0, scale))
end

---@brief VSync設定
---@param enabled boolean VSync有効フラグ
function PerformanceSettings:setVSync(enabled)
    self.enableVSync = enabled
    love.window.setVSync(enabled and 1 or 0)
end

---@brief 低品質モード設定
---@param enabled boolean 低品質モード有効フラグ
function PerformanceSettings:setLowQualityMode(enabled)
    self.lowQualityMode = enabled
    if enabled then
        self.resolutionScale = 0.5
        self.targetFps = 30
    else
        self.resolutionScale = 1.0
        self.targetFps = 60
    end
    self:applySettings()
end

---@brief 適応品質調整設定
---@param enabled boolean 適応品質調整有効フラグ
function PerformanceSettings:setAdaptiveQuality(enabled)
    self.adaptiveQuality = enabled
end

---@brief 自動最適化設定
---@param enabled boolean 自動最適化有効フラグ
function PerformanceSettings:setAutoOptimize(enabled)
    self.autoOptimize = enabled
end

---@brief パフォーマンス目標設定
---@param target string パフォーマンス目標（"quality", "balanced", "performance"）
function PerformanceSettings:setPerformanceTarget(target)
    if target == "quality" then
        self.performanceTarget = "quality"
        self.resolutionScale = 1.0
        self.targetFps = 60
        self.lowQualityMode = false
    elseif target == "balanced" then
        self.performanceTarget = "balanced"
        self.resolutionScale = 0.8
        self.targetFps = 60
        self.lowQualityMode = false
    elseif target == "performance" then
        self.performanceTarget = "performance"
        self.resolutionScale = 0.6
        self.targetFps = 60
        self.lowQualityMode = true
    end
    self:applySettings()
end

---@brief 設定適用
function PerformanceSettings:applySettings()
    -- VSync設定
    love.window.setVSync(self.enableVSync and 1 or 0)
    
    -- フィルタリング設定
    if self.lowQualityMode then
        love.graphics.setDefaultFilter("nearest", "nearest")
    else
        love.graphics.setDefaultFilter("linear", "linear")
    end
    
    -- フレームレート制限（Love2Dではタイマーで制御）
    self.maxFrameTime = 1000 / self.targetFps
end

---@brief 適応品質調整実行
---@param currentFps number 現在のFPS
---@param frameTime number フレーム時間（ms）
function PerformanceSettings:adaptiveAdjust(currentFps, frameTime)
    if not self.adaptiveQuality then
        return
    end
    
    -- パフォーマンスが悪い場合は品質を下げる
    if currentFps < self.targetFps * 0.8 or frameTime > self.maxFrameTime * 1.2 then
        if self.resolutionScale > 0.5 then
            self.resolutionScale = math.max(0.5, self.resolutionScale - 0.1)
            return true  -- 設定変更あり
        end
    end
    
    -- パフォーマンスが良い場合は品質を上げる
    if currentFps > self.targetFps * 1.1 and frameTime < self.maxFrameTime * 0.8 then
        if self.resolutionScale < 1.0 then
            self.resolutionScale = math.min(1.0, self.resolutionScale + 0.05)
            return true  -- 設定変更あり
        end
    end
    
    return false  -- 設定変更なし
end

---@brief 効果的解像度取得
---@param baseWidth number ベース幅
---@param baseHeight number ベース高さ
---@return number, number 効果的幅、効果的高さ
function PerformanceSettings:getEffectiveResolution(baseWidth, baseHeight)
    local effectiveWidth = math.floor(baseWidth * self.resolutionScale)
    local effectiveHeight = math.floor(baseHeight * self.resolutionScale)
    return effectiveWidth, effectiveHeight
end

---@brief フレーム制限チェック
---@param deltaTime number デルタタイム
---@return boolean フレーム制限が必要かどうか
function PerformanceSettings:shouldLimitFrame(deltaTime)
    if self.targetFps <= 0 then
        return false
    end
    
    local frameTime = deltaTime * 1000
    return frameTime < self.maxFrameTime
end

---@brief 設定情報取得
---@return table 設定情報
function PerformanceSettings:getSettings()
    return {
        targetFps = self.targetFps,
        resolutionScale = self.resolutionScale,
        enableVSync = self.enableVSync,
        lowQualityMode = self.lowQualityMode,
        adaptiveQuality = self.adaptiveQuality,
        autoOptimize = self.autoOptimize,
        performanceTarget = self.performanceTarget
    }
end

---@brief 設定をテーブルに変換
---@return table 設定データ
function PerformanceSettings:toTable()
    return {
        targetFps = self.targetFps,
        resolutionScale = self.resolutionScale,
        enableVSync = self.enableVSync,
        lowQualityMode = self.lowQualityMode,
        adaptiveQuality = self.adaptiveQuality,
        autoOptimize = self.autoOptimize,
        performanceTarget = self.performanceTarget
    }
end

---@brief テーブルから設定を復元
---@param data table 設定データ
function PerformanceSettings:fromTable(data)
    if type(data) ~= "table" then
        return false
    end
    
    self.targetFps = data.targetFps or 60
    self.resolutionScale = data.resolutionScale or 1.0
    self.enableVSync = data.enableVSync ~= false  -- デフォルトtrue
    self.lowQualityMode = data.lowQualityMode or false
    self.adaptiveQuality = data.adaptiveQuality or false
    self.autoOptimize = data.autoOptimize or false
    self.performanceTarget = data.performanceTarget or "balanced"
    
    self:applySettings()
    return true
end

---@brief デフォルト設定に戻す
function PerformanceSettings:resetToDefaults()
    self.targetFps = 60
    self.resolutionScale = 1.0
    self.enableVSync = true
    self.lowQualityMode = false
    self.adaptiveQuality = false
    self.autoOptimize = false
    self.performanceTarget = "balanced"
    self:applySettings()
end

---@brief パフォーマンス統計文字列取得
---@return string パフォーマンス統計
function PerformanceSettings:getStatsString()
    return string.format(
        "目標: %dFPS | 解像度: %.0f%% | 品質: %s | VSync: %s | 適応: %s",
        self.targetFps,
        self.resolutionScale * 100,
        self.performanceTarget,
        self.enableVSync and "ON" or "OFF",
        self.adaptiveQuality and "ON" or "OFF"
    )
end

return PerformanceSettings