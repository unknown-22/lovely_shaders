---@file core/channel_manager.lua
---@brief 入力チャンネル管理モジュール
---@details シェーダーの入力テクスチャ（iChannel0-3）を管理

---@class Channel
---@field texture love.Image|nil テクスチャオブジェクト
---@field type string チャンネルタイプ ("image", "buffer", "noise")
---@field path string|nil ファイルパス
---@field wrapMode string ラップモード ("repeat", "clamp", "mirror")
---@field filter string フィルタリング ("linear", "nearest")

---@class ChannelManager
---@field channels Channel[] チャンネル配列（1-4）
---@field defaultTextures table<string, love.Image> デフォルトテクスチャ
local ChannelManager = {}
ChannelManager.__index = ChannelManager

---@brief 新しいChannelManagerインスタンスを作成
---@return ChannelManager
function ChannelManager.new()
    local self = setmetatable({}, ChannelManager)
    
    self.channels = {}
    for i = 1, 4 do
        self.channels[i] = {
            texture = nil,
            type = "none",
            path = nil,
            wrapMode = "repeat",
            filter = "linear"
        }
    end
    
    self.defaultTextures = {}
    self:loadDefaultTextures()
    
    return self
end

---@brief デフォルトテクスチャを読み込む
function ChannelManager:loadDefaultTextures()
    local defaultImages = {
        noise = "asset/image/noise-gray-texture.png",
        gradient = "asset/image/gradient-linear-texture.png",
        checker = "asset/image/checker-texture.png",
        circle = "asset/image/circle-texture.png",
        uvgrid = "asset/image/uv-grid-texture.png"
    }
    
    for name, path in pairs(defaultImages) do
        local success, texture = pcall(love.graphics.newImage, path)
        if success and texture then
            self.defaultTextures[name] = texture
            print(string.format("[ChannelManager] デフォルトテクスチャ読み込み成功: %s", name))
        else
            print(string.format("[ChannelManager] デフォルトテクスチャ読み込み失敗: %s - %s", name, tostring(texture)))
        end
    end
end

---@brief チャンネルに画像を設定
---@param channelIndex number チャンネル番号（1-4）
---@param imagePath string 画像ファイルパス
---@return boolean 成功フラグ
function ChannelManager:setImage(channelIndex, imagePath)
    if channelIndex < 1 or channelIndex > 4 then
        print(string.format("[ChannelManager] 無効なチャンネル番号: %d", channelIndex))
        return false
    end
    
    local success, texture = pcall(love.graphics.newImage, imagePath)
    if success and texture then
        self.channels[channelIndex].texture = texture
        self.channels[channelIndex].type = "image"
        self.channels[channelIndex].path = imagePath
        self:applyTextureSettings(channelIndex)
        print(string.format("[ChannelManager] チャンネル%dに画像を設定: %s", channelIndex, imagePath))
        return true
    else
        print(string.format("[ChannelManager] 画像読み込み失敗: %s - %s", imagePath, tostring(texture)))
        return false
    end
end

---@brief チャンネルにデフォルトテクスチャを設定
---@param channelIndex number チャンネル番号（1-4）
---@param textureName string テクスチャ名 ("noise", "gradient", "checker", "circle", "uvgrid")
---@return boolean 成功フラグ
function ChannelManager:setDefaultTexture(channelIndex, textureName)
    if channelIndex < 1 or channelIndex > 4 then
        print(string.format("[ChannelManager] 無効なチャンネル番号: %d", channelIndex))
        return false
    end
    
    local texture = self.defaultTextures[textureName]
    if texture then
        self.channels[channelIndex].texture = texture
        self.channels[channelIndex].type = textureName
        self.channels[channelIndex].path = nil
        self:applyTextureSettings(channelIndex)
        print(string.format("[ChannelManager] チャンネル%dにデフォルトテクスチャを設定: %s", channelIndex, textureName))
        return true
    else
        print(string.format("[ChannelManager] 無効なテクスチャ名: %s", textureName))
        return false
    end
end

---@brief チャンネルをクリア
---@param channelIndex number チャンネル番号（1-4）
function ChannelManager:clearChannel(channelIndex)
    if channelIndex < 1 or channelIndex > 4 then
        print(string.format("[ChannelManager] 無効なチャンネル番号: %d", channelIndex))
        return
    end
    
    self.channels[channelIndex].texture = nil
    self.channels[channelIndex].type = "none"
    self.channels[channelIndex].path = nil
    print(string.format("[ChannelManager] チャンネル%dをクリア", channelIndex))
end

---@brief チャンネルのラップモードを設定
---@param channelIndex number チャンネル番号（1-4）
---@param wrapMode string ラップモード ("repeat", "clamp", "mirror")
function ChannelManager:setWrapMode(channelIndex, wrapMode)
    if channelIndex < 1 or channelIndex > 4 then
        return
    end
    
    if wrapMode == "repeat" or wrapMode == "clamp" or wrapMode == "mirror" then
        self.channels[channelIndex].wrapMode = wrapMode
        self:applyTextureSettings(channelIndex)
    end
end

---@brief チャンネルのフィルターモードを設定
---@param channelIndex number チャンネル番号（1-4）
---@param filter string フィルタリング ("linear", "nearest")
function ChannelManager:setFilter(channelIndex, filter)
    if channelIndex < 1 or channelIndex > 4 then
        return
    end
    
    if filter == "linear" or filter == "nearest" then
        self.channels[channelIndex].filter = filter
        self:applyTextureSettings(channelIndex)
    end
end

---@brief テクスチャ設定を適用
---@param channelIndex number チャンネル番号（1-4）
function ChannelManager:applyTextureSettings(channelIndex)
    local channel = self.channels[channelIndex]
    if channel.texture then
        -- ラップモードの設定
        local wrapMode = channel.wrapMode
        if wrapMode == "repeat" then
            channel.texture:setWrap("repeat", "repeat")
        elseif wrapMode == "clamp" then
            channel.texture:setWrap("clamp", "clamp")
        elseif wrapMode == "mirror" then
            channel.texture:setWrap("mirroredrepeat", "mirroredrepeat")
        end
        
        -- フィルターの設定
        channel.texture:setFilter(channel.filter, channel.filter)
    end
end

---@brief シェーダーにチャンネルを送信
---@param shader love.Shader シェーダーオブジェクト
function ChannelManager:sendToShader(shader)
    if not shader then
        return
    end
    
    local channelResolutions = {}
    
    for i = 1, 4 do
        local channel = self.channels[i]
        if channel.texture then
            -- テクスチャを送信
            local uniformName = string.format("iChannel%d", i - 1)
            if pcall(shader.send, shader, uniformName, channel.texture) then
                -- 解像度情報を準備
                local width = channel.texture:getWidth()
                local height = channel.texture:getHeight()
                channelResolutions[i] = {width, height, 1.0}
            end
        else
            -- 空のチャンネルは黒いテクスチャを設定
            channelResolutions[i] = {1, 1, 1}
        end
    end
    
    -- チャンネル解像度を送信
    if pcall(shader.send, shader, "iChannelResolution", unpack(channelResolutions)) then
        -- 成功
    end
end

---@brief チャンネル情報を取得
---@param channelIndex number チャンネル番号（1-4）
---@return Channel|nil
function ChannelManager:getChannel(channelIndex)
    if channelIndex < 1 or channelIndex > 4 then
        return nil
    end
    return self.channels[channelIndex]
end

---@brief 全チャンネル情報を取得
---@return Channel[]
function ChannelManager:getAllChannels()
    return self.channels
end

return ChannelManager