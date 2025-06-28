---@file core/shader_manager.lua
---@brief シェーダー管理モジュール
---@details シェーダーのコンパイル、エラーハンドリング、Uniform変数管理を行う

local ChannelManager = require("core.channel_manager")

---@class ShaderManager
---@field shader love.Shader 現在のシェーダー
---@field defaultShader love.Shader デフォルトシェーダー
---@field errors table エラーメッセージリスト
---@field lastCompileTime number 最後のコンパイル時刻
---@field quad love.SpriteBatch 描画用クワッド
---@field canvas love.Canvas 描画用キャンバス
---@field channelManager ChannelManager チャンネル管理
local ShaderManager = {}
ShaderManager.__index = ShaderManager

-- Love2DではデフォルトでフラグメントシェーダーのみでOK

---@brief シェーダーマネージャー新規作成
---@return ShaderManager
function ShaderManager.new()
    local self = setmetatable({}, ShaderManager)
    
    self.shader = nil
    self.defaultShader = nil
    self.errors = {}
    self.lastCompileTime = 0
    self.canvas = nil
    self.channelManager = ChannelManager.new()
    
    return self
end


---@brief デフォルトシェーダー読み込み
function ShaderManager:loadDefaultShader()
    local success, fragmentCode = pcall(love.filesystem.read, "shaders/default.glsl")
    if not success then
        self:addError("デフォルトシェーダーファイルが見つかりません: shaders/default.glsl", "error")
        return false
    end
    
    if type(fragmentCode) == "userdata" and fragmentCode.getString then
        fragmentCode = fragmentCode:getString()
    end
    return self:compile(fragmentCode)
end

---@brief シェーダーコンパイル
---@param fragmentCode string フラグメントシェーダーコード
---@return boolean コンパイル成功フラグ
function ShaderManager:compile(fragmentCode)
    if not fragmentCode or fragmentCode == "" then
        self:addError("シェーダーコードが空です", "error")
        return false
    end
    
    self.errors = {}
    self.lastCompileTime = love.timer.getTime()
    
    local success, newShader = pcall(love.graphics.newShader, fragmentCode)
    
    if success then
        if self.shader then
            self.shader:release()
        end
        self.shader = newShader
        self:addError("シェーダーコンパイル成功", "success")
        return true
    else
        local errorMsg = tostring(newShader)
        errorMsg = self:parseShaderError(errorMsg)
        self:addError("コンパイルエラー: " .. errorMsg, "error")
        return false
    end
end

---@brief シェーダーエラー解析
---@param errorMsg string 生のエラーメッセージ
---@return string 整形済みエラーメッセージ
function ShaderManager:parseShaderError(errorMsg)
    if not errorMsg then
        return "不明なエラー"
    end
    
    local line = errorMsg:match("0:(%d+)")
    if line then
        return string.format("行 %s: %s", line, errorMsg:match("%((.+)%)") or errorMsg)
    end
    
    return errorMsg
end

---@brief エラーメッセージ追加
---@param message string エラーメッセージ
---@param type string エラータイプ（"error", "warning", "success"）
function ShaderManager:addError(message, type)
    type = type or "error"
    local timestamp = os.date("%H:%M:%S")
    table.insert(self.errors, {
        message = message,
        type = type,
        timestamp = timestamp
    })
    
    if #self.errors > 50 then
        table.remove(self.errors, 1)
    end
    
    print(string.format("[%s] %s: %s", timestamp, type:upper(), message))
end

---@brief エラーリスト取得
---@return table エラーメッセージリスト
function ShaderManager:getErrors()
    local formattedErrors = {}
    for _, error in ipairs(self.errors) do
        table.insert(formattedErrors, string.format("[%s] %s", error.timestamp, error.message))
    end
    return formattedErrors
end

---@brief Uniform変数更新
---@param time number 経過時間
---@param deltaTime number デルタタイム
---@param frameCount number フレーム数
function ShaderManager:updateUniforms(time, deltaTime, frameCount)
    if not self.shader then
        return
    end
    
    local width, height = love.graphics.getDimensions()
    local mouseX, mouseY = love.mouse.getPosition()
    local mousePressed = love.mouse.isDown(1)
    
    local date = os.date("*t")
    local secondsInDay = date.hour * 3600 + date.min * 60 + date.sec
    
    local hasUniform = function(name)
        -- 複数の型でテストしてuniform変数の存在を確認
        local testValues = {
            0,                    -- float
            {0, 0},              -- vec2
            {0, 0, 0},           -- vec3
            {0, 0, 0, 0},        -- vec4
        }
        
        local success = false
        for _, testValue in ipairs(testValues) do
            success = pcall(function() self.shader:send(name, testValue) end)
            if success then break end
        end
        
        return success
    end
    
    if hasUniform("iTime") then
        self.shader:send("iTime", time)
    end
    
    if hasUniform("iTimeDelta") then
        self.shader:send("iTimeDelta", deltaTime)
    end
    
    if hasUniform("iFrame") then
        self.shader:send("iFrame", frameCount)
    end
    
    if hasUniform("iResolution") then
        -- シンプルに画面全体のサイズを使用
        self.shader:send("iResolution", {width, height, 1.0})
    end
    
    if hasUniform("iMouse") then
        local mouseZ = mousePressed and mouseX or -mouseX
        local mouseW = mousePressed and mouseY or -mouseY
        self.shader:send("iMouse", {mouseX, height - mouseY, mouseZ, height - mouseW})
    end
    
    if hasUniform("iDate") then
        self.shader:send("iDate", {date.year, date.month, date.day, secondsInDay})
    end
    
    -- チャンネルテクスチャを送信
    self.channelManager:sendToShader(self.shader)
end

---@brief シェーダー描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function ShaderManager:drawShader(x, y, width, height)
    if not self.shader then
        love.graphics.setColor(0.2, 0.2, 0.25, 1.0)
        love.graphics.rectangle("fill", x, y, width, height)
        
        love.graphics.setColor(0.6, 0.6, 0.6, 1.0)
        love.graphics.printf("シェーダーが読み込まれていません", x, y + height/2 - 10, width, "center")
        return
    end
    
    -- Love2Dシェーダーのより単純な描画方法
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader(self.shader)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setShader()
end

---@brief 現在のシェーダー取得
---@return love.Shader|nil 現在のシェーダー
function ShaderManager:getCurrentShader()
    return self.shader
end

---@brief シェーダー存在確認
---@return boolean シェーダーが存在するかどうか
function ShaderManager:hasShader()
    return self.shader ~= nil
end

---@brief チャンネルマネージャー取得
---@return ChannelManager
function ShaderManager:getChannelManager()
    return self.channelManager
end

---@brief リソース解放
function ShaderManager:release()
    if self.shader then
        self.shader:release()
        self.shader = nil
    end
    
    if self.defaultShader then
        self.defaultShader:release()
        self.defaultShader = nil
    end
    
    if self.quad then
        self.quad:release()
        self.quad = nil
    end
    
    if self.canvas then
        self.canvas:release()
        self.canvas = nil
    end
end

return ShaderManager