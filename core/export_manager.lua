---@file core/export_manager.lua
---@brief 画像エクスポート管理モジュール
---@details シェーダーを画像として出力する機能を提供

---@class ExportManager
---@field shaderManager ShaderManager シェーダーマネージャー参照
local ExportManager = {}
ExportManager.__index = ExportManager

---@brief 新しいExportManagerインスタンスを作成
---@param shaderManager ShaderManager シェーダーマネージャー
---@return ExportManager
function ExportManager.new(shaderManager)
    local self = setmetatable({}, ExportManager)
    
    self.shaderManager = shaderManager
    
    return self
end

---@brief シェーダーを画像として出力
---@param width number 出力画像の幅
---@param height number 出力画像の高さ
---@param filename string|nil 出力ファイル名（省略時は自動生成）
---@return boolean 成功フラグ
function ExportManager:exportImage(width, height, filename)
    if not self.shaderManager:hasShader() then
        print("[ExportManager] エクスポート失敗: シェーダーが読み込まれていません")
        return false
    end
    
    -- ファイル名の生成
    if not filename then
        local timestamp = os.date("%Y%m%d_%H%M%S")
        filename = string.format("shader_export_%s.png", timestamp)
    end
    
    -- 拡張子を確認
    if not filename:match("%.png$") then
        filename = filename .. ".png"
    end
    
    -- 出力ディレクトリの確保
    local outputDir = "exports"
    if not love.filesystem.getInfo(outputDir) then
        local success = love.filesystem.createDirectory(outputDir)
        if not success then
            print("[ExportManager] エクスポート失敗: 出力ディレクトリの作成に失敗 - " .. outputDir)
            return false
        end
    end
    
    local fullPath = outputDir .. "/" .. filename
    
    -- キャンバスの作成
    local success, canvas = pcall(love.graphics.newCanvas, width, height)
    if not success then
        print("[ExportManager] エクスポート失敗: キャンバスの作成に失敗 - " .. tostring(canvas))
        return false
    end
    
    -- 現在の状態を保存
    local originalCanvas = love.graphics.getCanvas()
    local originalShader = love.graphics.getShader()
    local originalColor = {love.graphics.getColor()}
    
    -- キャンバスに描画
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)
    
    -- シェーダーのuniform変数を更新
    local shader = self.shaderManager:getCurrentShader()
    if shader then
        -- 解像度を出力サイズに設定
        local hasUniform = function(name)
            local testValues = {
                0,                    -- float
                {0, 0},              -- vec2
                {0, 0, 0},           -- vec3
                {0, 0, 0, 0},        -- vec4
            }
            
            local testSuccess = false
            for _, testValue in ipairs(testValues) do
                testSuccess = pcall(function() shader:send(name, testValue) end)
                if testSuccess then break end
            end
            
            return testSuccess
        end
        
        if hasUniform("iResolution") then
            shader:send("iResolution", {width, height, 1.0})
        end
        
        -- チャンネルテクスチャを送信
        self.shaderManager:getChannelManager():sendToShader(shader)
        
        love.graphics.setShader(shader)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, width, height)
    end
    
    -- 状態を復元
    love.graphics.setCanvas(originalCanvas)
    love.graphics.setShader(originalShader)
    love.graphics.setColor(unpack(originalColor))
    
    -- ImageDataに変換
    local imageData = canvas:newImageData()
    
    -- ファイルに保存
    local saveSuccess = imageData:encode("png", fullPath)
    
    -- リソース解放
    canvas:release()
    
    if saveSuccess then
        print(string.format("[ExportManager] 画像エクスポート成功: %s (%dx%d)", fullPath, width, height))
        return true
    else
        print(string.format("[ExportManager] 画像エクスポート失敗: %s", fullPath))
        return false
    end
end

---@brief プリセット解像度でエクスポート
---@param preset string プリセット名 ("HD", "FHD", "4K", "8K")
---@param filename string|nil 出力ファイル名
---@return boolean 成功フラグ
function ExportManager:exportWithPreset(preset, filename)
    local resolutions = {
        HD = {1280, 720},
        FHD = {1920, 1080},
        ["4K"] = {3840, 2160},
        ["8K"] = {7680, 4320}
    }
    
    local resolution = resolutions[preset]
    if not resolution then
        print("[ExportManager] 無効なプリセット: " .. tostring(preset))
        return false
    end
    
    return self:exportImage(resolution[1], resolution[2], filename)
end

---@brief 現在の画面サイズでエクスポート
---@param filename string|nil 出力ファイル名
---@return boolean 成功フラグ
function ExportManager:exportCurrentSize(filename)
    local width, height = love.graphics.getDimensions()
    return self:exportImage(width, height, filename)
end

---@brief エクスポート可能な最大解像度を取得
---@return number, number 最大幅、最大高さ
function ExportManager:getMaxResolution()
    local maxSize = love.graphics.getSystemLimits().texturesize
    return maxSize, maxSize
end

---@brief エクスポートディレクトリのパスを取得
---@return string ディレクトリパス
function ExportManager:getExportDirectory()
    return love.filesystem.getSaveDirectory() .. "/exports"
end

---@brief エクスポート設定の検証
---@param width number 幅
---@param height number 高さ
---@return boolean, string 有効性、エラーメッセージ
function ExportManager:validateExportSettings(width, height)
    if not width or not height or width <= 0 or height <= 0 then
        return false, "無効な解像度が指定されました"
    end
    
    local maxSize = love.graphics.getSystemLimits().texturesize
    if width > maxSize or height > maxSize then
        return false, string.format("解像度が上限を超えています (最大: %dx%d)", maxSize, maxSize)
    end
    
    if not self.shaderManager:hasShader() then
        return false, "シェーダーが読み込まれていません"
    end
    
    return true, ""
end

return ExportManager