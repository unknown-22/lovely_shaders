---@file core/performance_monitor.lua
---@brief パフォーマンス監視モジュール
---@details FPS、フレーム時間、メモリ使用量などの統計情報を管理

---@class PerformanceMonitor
---@field fpsHistory table FPS履歴
---@field frameTimeHistory table フレーム時間履歴
---@field maxHistory number 履歴の最大保持数
---@field avgFps number 平均FPS
---@field avgFrameTime number 平均フレーム時間
---@field maxFrameTime number 最大フレーム時間
---@field minFrameTime number 最小フレーム時間
---@field lastUpdateTime number 前回更新時刻
---@field updateInterval number 更新間隔
---@field enabled boolean パフォーマンス監視有効フラグ
---@field showDetails boolean 詳細表示フラグ
local PerformanceMonitor = {}
PerformanceMonitor.__index = PerformanceMonitor

---@brief PerformanceMonitorコンストラクタ
---@return PerformanceMonitor
function PerformanceMonitor.new()
    local self = setmetatable({}, PerformanceMonitor)
    self.fpsHistory = {}
    self.frameTimeHistory = {}
    self.maxHistory = 60  -- 1秒分（60FPS想定）
    self.avgFps = 0
    self.avgFrameTime = 0
    self.maxFrameTime = 0
    self.minFrameTime = math.huge
    self.lastUpdateTime = 0
    self.updateInterval = 0.1  -- 100ms間隔で更新
    self.enabled = true
    self.showDetails = false
    return self
end

---@brief パフォーマンス情報更新
---@param dt number デルタタイム
function PerformanceMonitor:update(dt)
    if not self.enabled then
        return
    end
    
    local currentTime = love.timer.getTime()
    
    -- 更新間隔チェック
    if currentTime - self.lastUpdateTime < self.updateInterval then
        return
    end
    
    self.lastUpdateTime = currentTime
    
    local fps = love.timer.getFPS()
    local frameTime = dt * 1000  -- ミリ秒に変換
    
    -- 履歴に追加
    table.insert(self.fpsHistory, fps)
    table.insert(self.frameTimeHistory, frameTime)
    
    -- 履歴サイズ制限
    if #self.fpsHistory > self.maxHistory then
        table.remove(self.fpsHistory, 1)
    end
    if #self.frameTimeHistory > self.maxHistory then
        table.remove(self.frameTimeHistory, 1)
    end
    
    -- 統計計算
    self:calculateStats()
end

---@brief 統計情報計算
function PerformanceMonitor:calculateStats()
    if #self.fpsHistory == 0 then
        return
    end
    
    -- 平均FPS計算
    local fpsSum = 0
    for _, fps in ipairs(self.fpsHistory) do
        fpsSum = fpsSum + fps
    end
    self.avgFps = fpsSum / #self.fpsHistory
    
    -- フレーム時間統計計算
    local frameTimeSum = 0
    self.maxFrameTime = 0
    self.minFrameTime = math.huge
    
    for _, frameTime in ipairs(self.frameTimeHistory) do
        frameTimeSum = frameTimeSum + frameTime
        self.maxFrameTime = math.max(self.maxFrameTime, frameTime)
        self.minFrameTime = math.min(self.minFrameTime, frameTime)
    end
    
    self.avgFrameTime = frameTimeSum / #self.frameTimeHistory
end

---@brief パフォーマンス情報描画
---@param x number X座標
---@param y number Y座標
function PerformanceMonitor:draw(x, y)
    if not self.enabled then
        return
    end
    
    local currentFps = love.timer.getFPS()
    local memUsage = math.floor(collectgarbage("count"))
    
    -- 基本情報
    love.graphics.setColor(0.95, 0.95, 0.96, 0.8)
    
    if self.showDetails then
        -- 詳細表示
        local lineHeight = 16
        local currentY = y
        
        love.graphics.print(string.format("現在FPS: %d", currentFps), x, currentY)
        currentY = currentY + lineHeight
        
        love.graphics.print(string.format("平均FPS: %.1f", self.avgFps), x, currentY)
        currentY = currentY + lineHeight
        
        love.graphics.print(string.format("フレーム時間: %.2fms", self.avgFrameTime), x, currentY)
        currentY = currentY + lineHeight
        
        love.graphics.print(string.format("最大フレーム時間: %.2fms", self.maxFrameTime), x, currentY)
        currentY = currentY + lineHeight
        
        love.graphics.print(string.format("最小フレーム時間: %.2fms", self.minFrameTime), x, currentY)
        currentY = currentY + lineHeight
        
        love.graphics.print(string.format("メモリ使用量: %dKB", memUsage), x, currentY)
        currentY = currentY + lineHeight
        
        -- GPU情報（Love2Dで取得可能な範囲）
        local graphicsInfo = love.graphics.getStats()
        if graphicsInfo then
            love.graphics.print(string.format("描画コール: %d", graphicsInfo.drawcalls or 0), x, currentY)
            currentY = currentY + lineHeight
            
            if graphicsInfo.texturememory then
                love.graphics.print(string.format("テクスチャメモリ: %.1fMB", graphicsInfo.texturememory / 1024 / 1024), x, currentY)
                currentY = currentY + lineHeight
            end
        end
        
        -- FPSカラー表示
        if currentFps >= 55 then
            love.graphics.setColor(0.30, 0.69, 0.31, 0.8)  -- 緑（良好）
        elseif currentFps >= 30 then
            love.graphics.setColor(1.00, 0.76, 0.03, 0.8)  -- 黄（注意）
        else
            love.graphics.setColor(0.95, 0.26, 0.21, 0.8)  -- 赤（警告）
        end
        
        love.graphics.print("■", x - 10, y)
    else
        -- 簡易表示
        love.graphics.print(string.format("FPS: %d | Mem: %dKB", currentFps, memUsage), x, y)
    end
end

---@brief FPS履歴グラフ描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function PerformanceMonitor:drawFpsGraph(x, y, width, height)
    if not self.enabled or #self.fpsHistory < 2 then
        return
    end
    
    -- 背景
    love.graphics.setColor(0.05, 0.05, 0.06, 0.8)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- グリッド
    love.graphics.setColor(0.20, 0.20, 0.23, 0.5)
    local gridLines = 4
    for i = 1, gridLines do
        local gridY = y + (height / gridLines) * i
        love.graphics.line(x, gridY, x + width, gridY)
    end
    
    -- FPSライン
    love.graphics.setColor(0.33, 0.60, 0.99, 1.0)
    local maxFps = 60
    local minFps = 0
    
    local points = {}
    for i, fps in ipairs(self.fpsHistory) do
        local normalizedFps = (fps - minFps) / (maxFps - minFps)
        local pointX = x + (width / (#self.fpsHistory - 1)) * (i - 1)
        local pointY = y + height - (normalizedFps * height)
        table.insert(points, pointX)
        table.insert(points, pointY)
    end
    
    if #points >= 4 then
        love.graphics.line(points)
    end
    
    -- 60FPS基準線
    love.graphics.setColor(0.30, 0.69, 0.31, 0.7)
    local targetY = y + height - ((60 - minFps) / (maxFps - minFps) * height)
    love.graphics.line(x, targetY, x + width, targetY)
    
    -- ラベル
    love.graphics.setColor(0.95, 0.95, 0.96, 0.8)
    love.graphics.print("60", x + width + 2, targetY - 8)
    love.graphics.print("0", x + width + 2, y + height - 8)
end

---@brief パフォーマンス監視有効切り替え
function PerformanceMonitor:toggle()
    self.enabled = not self.enabled
end

---@brief 詳細表示切り替え
function PerformanceMonitor:toggleDetails()
    self.showDetails = not self.showDetails
end

---@brief パフォーマンス監視有効確認
---@return boolean
function PerformanceMonitor:isEnabled()
    return self.enabled
end

---@brief 詳細表示確認
---@return boolean
function PerformanceMonitor:isShowingDetails()
    return self.showDetails
end

---@brief 現在のFPS取得
---@return number
function PerformanceMonitor:getCurrentFps()
    return love.timer.getFPS()
end

---@brief 平均FPS取得
---@return number
function PerformanceMonitor:getAverageFps()
    return self.avgFps
end

---@brief 平均フレーム時間取得
---@return number
function PerformanceMonitor:getAverageFrameTime()
    return self.avgFrameTime
end

---@brief パフォーマンス警告チェック
---@return boolean 警告状態かどうか
function PerformanceMonitor:isPerformanceWarning()
    return self.avgFps < 30 or self.avgFrameTime > 33.33  -- 30FPS以下または33ms以上
end

---@brief パフォーマンス統計取得
---@return table パフォーマンス統計
function PerformanceMonitor:getStats()
    return {
        currentFps = love.timer.getFPS(),
        averageFps = self.avgFps,
        averageFrameTime = self.avgFrameTime,
        maxFrameTime = self.maxFrameTime,
        minFrameTime = self.minFrameTime,
        memoryUsage = collectgarbage("count"),
        isWarning = self:isPerformanceWarning()
    }
end

---@brief リセット
function PerformanceMonitor:reset()
    self.fpsHistory = {}
    self.frameTimeHistory = {}
    self.avgFps = 0
    self.avgFrameTime = 0
    self.maxFrameTime = 0
    self.minFrameTime = math.huge
end

return PerformanceMonitor