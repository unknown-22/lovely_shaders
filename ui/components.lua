---@file ui/components.lua
---@brief UIコンポーネントモジュール
---@details 基本的なUIコンポーネント（ボタン、パネル等）を提供

---@class Components
---@field buttons table ボタンリスト
---@field font love.Font フォント
local Components = {}
Components.__index = Components

local COLORS = {
    bg_primary = {0.09, 0.09, 0.11, 1.0},
    bg_secondary = {0.12, 0.12, 0.14, 1.0},
    bg_tertiary = {0.16, 0.16, 0.18, 1.0},
    text_primary = {0.95, 0.95, 0.96, 1.0},
    text_secondary = {0.60, 0.60, 0.64, 1.0},
    accent_primary = {0.33, 0.60, 0.99, 1.0},
    accent_hover = {0.40, 0.67, 1.00, 1.0},
    accent_active = {0.27, 0.50, 0.85, 1.0},
    border = {0.20, 0.20, 0.23, 1.0},
}

---@brief UIコンポーネント新規作成
---@return Components
function Components.new()
    local self = setmetatable({}, Components)
    
    self.buttons = {}
    -- UI用フォント設定
    local fontPath = "asset/font/UDEVGothic35HSJPDOC-Regular.ttf"
    local success, uiFont = pcall(love.graphics.newFont, fontPath, 13)
    if success then
        self.font = uiFont
    else
        self.font = love.graphics.getFont()
    end
    
    return self
end

---@brief ボタン描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
---@param text string ボタンテキスト
---@param action function クリック時のアクション
function Components:drawButton(x, y, width, height, text, action)
    local mouseX, mouseY = love.mouse.getPosition()
    local isHovered = mouseX >= x and mouseX <= x + width and mouseY >= y and mouseY <= y + height
    local isPressed = isHovered and love.mouse.isDown(1)
    
    local buttonColor = COLORS.bg_tertiary
    if isPressed then
        buttonColor = COLORS.accent_active
    elseif isHovered then
        buttonColor = COLORS.accent_hover
    end
    
    love.graphics.setColor(buttonColor)
    love.graphics.rectangle("fill", x, y, width, height, 6)
    
    love.graphics.setColor(COLORS.border)
    love.graphics.rectangle("line", x, y, width, height, 6)
    
    love.graphics.setColor(COLORS.text_primary)
    local textWidth = self.font:getWidth(text)
    local textHeight = self.font:getHeight()
    love.graphics.print(text, x + (width - textWidth) / 2, y + (height - textHeight) / 2)
    
    local buttonData = {
        x = x, y = y, width = width, height = height,
        action = action, text = text
    }
    
    local buttonId = string.format("%d_%d_%s", x, y, text)
    self.buttons[buttonId] = buttonData
end

---@brief パネル描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
---@param title string パネルタイトル
function Components:drawPanel(x, y, width, height, title)
    love.graphics.setColor(COLORS.bg_secondary)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(COLORS.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    if title then
        love.graphics.setColor(COLORS.bg_tertiary)
        love.graphics.rectangle("fill", x, y, width, 24)
        
        love.graphics.setColor(COLORS.text_primary)
        love.graphics.print(title, x + 8, y + 6)
        
        love.graphics.setColor(COLORS.border)
        love.graphics.line(x, y + 24, x + width, y + 24)
    end
end

---@brief テキストエリア描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
---@param text string テキスト内容
---@param lineNumbers boolean 行番号表示フラグ
function Components:drawTextArea(x, y, width, height, text, lineNumbers)
    local lineNumberWidth = lineNumbers and 50 or 0
    local textAreaX = x + lineNumberWidth
    local textAreaWidth = width - lineNumberWidth
    
    love.graphics.setColor(COLORS.bg_primary)
    love.graphics.rectangle("fill", x, y, width, height)
    
    if lineNumbers then
        love.graphics.setColor(COLORS.bg_secondary)
        love.graphics.rectangle("fill", x, y, lineNumberWidth, height)
        
        love.graphics.setColor(COLORS.border)
        love.graphics.line(x + lineNumberWidth, y, x + lineNumberWidth, y + height)
    end
    
    love.graphics.setColor(COLORS.border)
    love.graphics.rectangle("line", x, y, width, height)
    
    if text and text ~= "" then
        local lines = {}
        for line in text:gmatch("[^\r\n]*") do
            table.insert(lines, line)
        end
        
        local lineHeight = self.font:getHeight() + 2
        local startY = y + 8
        
        love.graphics.setFont(self.font)
        
        for i, line in ipairs(lines) do
            local currentY = startY + (i - 1) * lineHeight
            
            if currentY >= y and currentY <= y + height then
                if lineNumbers then
                    love.graphics.setColor(COLORS.text_secondary)
                    love.graphics.printf(tostring(i), x + 4, currentY, lineNumberWidth - 8, "right")
                end
                
                love.graphics.setColor(COLORS.text_primary)
                love.graphics.print(line, textAreaX + 8, currentY)
            end
        end
    end
end

---@brief スライダー描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param label string ラベル
---@param value number 現在値 (0.0-1.0)
---@param callback function 値変更時のコールバック
---@return number 新しい値
function Components:drawSlider(x, y, width, label, value, callback)
    local height = 20
    local trackHeight = 4
    local handleSize = 16
    
    love.graphics.setColor(COLORS.text_secondary)
    love.graphics.print(label, x, y - 20)
    
    local trackY = y + (height - trackHeight) / 2
    love.graphics.setColor(COLORS.bg_tertiary)
    love.graphics.rectangle("fill", x, trackY, width, trackHeight, 2)
    
    local handleX = x + (width - handleSize) * value
    local handleY = y + (height - handleSize) / 2
    
    local mouseX, mouseY = love.mouse.getPosition()
    local isHovered = mouseX >= handleX and mouseX <= handleX + handleSize and 
                     mouseY >= handleY and mouseY <= handleY + handleSize
    
    local handleColor = isHovered and COLORS.accent_hover or COLORS.accent_primary
    love.graphics.setColor(handleColor)
    love.graphics.circle("fill", handleX + handleSize / 2, handleY + handleSize / 2, handleSize / 2)
    
    if love.mouse.isDown(1) and isHovered then
        local newValue = math.max(0, math.min(1, (mouseX - x) / width))
        if callback then
            callback(newValue)
        end
        return newValue
    end
    
    return value
end

---@brief マウス押下処理
---@param x number マウスX座標
---@param y number マウスY座標
function Components:mousepressed(x, y)
    for _, button in pairs(self.buttons) do
        if x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height then
            if button.action then
                button.action()
            end
            break
        end
    end
    
    self.buttons = {}
end

---@brief エラーメッセージ描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param message string エラーメッセージ
function Components:drawError(x, y, width, message)
    local padding = 8
    local textHeight = self.font:getHeight()
    local height = textHeight + padding * 2
    
    love.graphics.setColor(0.95, 0.26, 0.21, 0.1)
    love.graphics.rectangle("fill", x, y, width, height, 4)
    
    love.graphics.setColor(0.95, 0.26, 0.21, 1.0)
    love.graphics.rectangle("line", x, y, width, height, 4)
    
    love.graphics.setColor(0.95, 0.26, 0.21, 1.0)
    love.graphics.print(message, x + padding, y + padding)
end

---@brief 成功メッセージ描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param message string 成功メッセージ
function Components:drawSuccess(x, y, width, message)
    local padding = 8
    local textHeight = self.font:getHeight()
    local height = textHeight + padding * 2
    
    love.graphics.setColor(0.30, 0.69, 0.31, 0.1)
    love.graphics.rectangle("fill", x, y, width, height, 4)
    
    love.graphics.setColor(0.30, 0.69, 0.31, 1.0)
    love.graphics.rectangle("line", x, y, width, height, 4)
    
    love.graphics.setColor(0.30, 0.69, 0.31, 1.0)
    love.graphics.print(message, x + padding, y + padding)
end

return Components