---@file main.lua
---@brief Lovely Shadersメインエントリーポイント
---@details Love2Dアプリケーションのメイン処理を統括

local ShaderManager = require("core.shader_manager")
local FileManager = require("core.file_manager")
local Editor = require("ui.editor")
local Components = require("ui.components")

---@class App
---@field shaderManager ShaderManager シェーダー管理
---@field fileManager FileManager ファイル管理
---@field editor Editor テキストエディタ
---@field components Components UIコンポーネント
---@field showEditor boolean エディタ表示フラグ
---@field time number 経過時間
---@field frameCount number フレーム数
---@field mousePressed boolean マウス押下状態
local App = {}

local EDITOR_WIDTH_RATIO = 0.4
local CONSOLE_HEIGHT = 140
local PANEL_HEIGHT = 200

---@brief Love2D初期化
function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    
    -- フォント設定
    local fontPath = "asset/font/UDEVGothic35HSJPDOC-Regular.ttf"
    local success, font = pcall(love.graphics.newFont, fontPath, 14)
    if success then
        love.graphics.setFont(font)
        print("フォントを読み込みました: " .. fontPath)
    else
        print("フォント読み込み失敗、デフォルトフォントを使用: " .. tostring(font))
    end
    
    App.shaderManager = ShaderManager.new()
    App.fileManager = FileManager.new()
    App.editor = Editor.new()
    App.components = Components.new()
    
    App.showEditor = true
    App.time = 0
    App.frameCount = 0
    App.mousePressed = false
    
    App.shaderManager:loadDefaultShader()
end

---@brief Love2D更新処理
---@param dt number デルタタイム
function love.update(dt)
    App.time = App.time + dt
    App.frameCount = App.frameCount + 1
    
    App.shaderManager:updateUniforms(App.time, dt, App.frameCount)
    App.editor:update(dt)
end

---@brief Love2D描画処理
function love.draw()
    local width, height = love.graphics.getDimensions()
    
    if App.showEditor then
        local editorWidth = math.floor(width * EDITOR_WIDTH_RATIO)
        local previewWidth = width - editorWidth
        local previewHeight = height - PANEL_HEIGHT
        
        App:drawEditor(editorWidth, height - CONSOLE_HEIGHT - PANEL_HEIGHT)
        App:drawConsole(0, height - CONSOLE_HEIGHT - PANEL_HEIGHT, editorWidth, CONSOLE_HEIGHT)
        App:drawChannelSettings(0, height - PANEL_HEIGHT, editorWidth, PANEL_HEIGHT)
        App:drawPreview(editorWidth, 0, previewWidth, previewHeight)
        App:drawParameterPanel(editorWidth, previewHeight, previewWidth, PANEL_HEIGHT)
    else
        App:drawPreview(0, 0, width, height)
    end
    
    App:drawMenuBar(width)
    App:drawStats()
end

---@brief メニューバー描画
---@param width number 画面幅
function App:drawMenuBar(width)
    local MENU_HEIGHT = 40
    
    love.graphics.setColor(0.12, 0.12, 0.14, 1.0)
    love.graphics.rectangle("fill", 0, 0, width, MENU_HEIGHT)
    
    love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
    love.graphics.rectangle("fill", 0, MENU_HEIGHT - 1, width, 1)
    
    local buttons = {
        {text = "保存", x = 10, action = function() App.fileManager:save(App.editor:getText()) end},
        {text = "開く", x = 70, action = function() 
            local content = App.fileManager:load()
            if content then App.editor:setText(content) end
        end},
        {text = "コンパイル", x = 130, action = function() App.shaderManager:compile(App.editor:getText()) end},
        {text = "エディタ切替", x = 220, action = function() App.showEditor = not App.showEditor end},
        {text = "ヘルプ", x = 340, action = function() print("ヘルプ機能は未実装") end}
    }
    
    for _, button in ipairs(buttons) do
        App.components:drawButton(button.x, 8, 60, 24, button.text, button.action)
    end
end

---@brief エディタ描画
---@param width number エディタ幅
---@param height number エディタ高さ
function App:drawEditor(width, height)
    love.graphics.setColor(0.09, 0.09, 0.11, 1.0)
    love.graphics.rectangle("fill", 0, 40, width, height)
    
    App.editor:draw(16, 56, width - 32, height - 32)
end

---@brief コンソール描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function App:drawConsole(x, y, width, height)
    love.graphics.setColor(0.05, 0.05, 0.06, 1.0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(0.12, 0.12, 0.14, 1.0)
    love.graphics.rectangle("fill", x, y, width, 24)
    
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print("コンソール", x + 8, y + 6)
    
    local errors = App.shaderManager:getErrors()
    love.graphics.setColor(0.95, 0.26, 0.21, 1.0)
    for i, error in ipairs(errors) do
        if i <= 5 then
            love.graphics.print(error, x + 8, y + 24 + (i * 20))
        end
    end
end

---@brief チャンネル設定描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function App:drawChannelSettings(x, y, width, height)
    love.graphics.setColor(0.12, 0.12, 0.14, 1.0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print("チャンネル設定", x + 8, y + 8)
    love.graphics.print("（Phase 2で実装予定）", x + 8, y + 32)
end

---@brief プレビュー描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function App:drawPreview(x, y, width, height)
    love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    App.shaderManager:drawShader(x, y, width, height)
end

---@brief パラメータパネル描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function App:drawParameterPanel(x, y, width, height)
    love.graphics.setColor(0.12, 0.12, 0.14, 1.0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print("パラメータ", x + 8, y + 8)
    love.graphics.print("（Phase 3で実装予定）", x + 8, y + 32)
end

---@brief 統計情報描画
function App:drawStats()
    local fps = love.timer.getFPS()
    local memUsage = math.floor(collectgarbage("count"))
    
    love.graphics.setColor(0.95, 0.95, 0.96, 0.7)
    love.graphics.print(string.format("FPS: %d | Memory: %dKB", fps, memUsage), 10, love.graphics.getHeight() - 20)
end

---@brief マウス押下処理
---@param x number X座標
---@param y number Y座標
---@param button number ボタン番号
function love.mousepressed(x, y, button)
    if button == 1 then
        App.mousePressed = true
        App.components:mousepressed(x, y)
        App.editor:mousepressed(x, y)
    end
end

---@brief マウス離上処理
---@param x number X座標
---@param y number Y座標
---@param button number ボタン番号
function love.mousereleased(x, y, button)
    if button == 1 then
        App.mousePressed = false
    end
end

---@brief キー押下処理
---@param key string キー名
function love.keypressed(key)
    if key == "f5" then
        App.shaderManager:compile(App.editor:getText())
    elseif key == "f11" then
        local _ = love.window.setFullscreen(not love.window.getFullscreen())
    elseif key == "escape" then
        love.event.quit()
    elseif love.keyboard.isDown("lctrl" --[[@as love.KeyConstant]]) or love.keyboard.isDown("rctrl" --[[@as love.KeyConstant]]) then
        if key == "s" then
            App.fileManager:save(App.editor:getText())
        elseif key == "o" then
            local content = App.fileManager:load()
            if content then App.editor:setText(content) end
        elseif key == "e" then
            App.showEditor = not App.showEditor
        end
    else
        App.editor:keypressed(key)
    end
end

---@brief テキスト入力処理
---@param text string 入力テキスト
function love.textinput(text)
    App.editor:textinput(text)
end