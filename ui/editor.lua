---@file ui/editor.lua
---@brief テキストエディタモジュール
---@details シェーダーコード編集用のテキストエディタ機能を提供

---@class Editor
---@field text string エディタテキスト
---@field lines table テキスト行配列
---@field cursorLine number カーソル行
---@field cursorColumn number カーソル列
---@field scrollOffset number スクロールオフセット
---@field font love.Font エディタフォント
---@field lineHeight number 行の高さ
---@field isActive boolean アクティブ状態
---@field selectionStart table 選択開始位置
---@field selectionEnd table 選択終了位置
local Editor = {}
Editor.__index = Editor

local COLORS = {
    bg_primary = {0.09, 0.09, 0.11, 1.0},
    bg_secondary = {0.12, 0.12, 0.14, 1.0},
    text_primary = {0.95, 0.95, 0.96, 1.0},
    text_secondary = {0.60, 0.60, 0.64, 1.0},
    text_disabled = {0.35, 0.35, 0.40, 1.0},
    accent_primary = {0.33, 0.60, 0.99, 1.0},
    border = {0.20, 0.20, 0.23, 1.0},
}

---@brief エディタ新規作成
---@return Editor
function Editor.new()
    local self = setmetatable({}, Editor)
    
    self.text = ""
    self.lines = {""}
    self.cursorLine = 1
    self.cursorColumn = 1
    self.scrollOffset = 0
    -- エディタ用等幅フォント設定
    local fontPath = "asset/font/UDEVGothic35HSJPDOC-Regular.ttf"
    local success, editorFont = pcall(love.graphics.newFont, fontPath, 14)
    if success then
        self.font = editorFont
    else
        self.font = love.graphics.getFont()
    end
    self.lineHeight = self.font:getHeight() + 2
    self.isActive = false
    self.selectionStart = nil
    self.selectionEnd = nil
    
    self:loadDefaultShader()
    
    return self
end

---@brief デフォルトシェーダー読み込み
function Editor:loadDefaultShader()
    local success, content = pcall(love.filesystem.read, "shaders/default.glsl")
    if success then
        if type(content) == "userdata" and content.getString then
            content = content:getString()
        end
        self:setText(content)
    else
        self:setText(self:getDefaultContent())
    end
end

---@brief デフォルトコンテンツ取得
---@return string デフォルトシェーダーコンテンツ
function Editor:getDefaultContent()
    return [[// Love2D互換シェーダー（Shadertoy形式をベース）

uniform float iTime;
uniform vec3 iResolution;
uniform vec4 iMouse;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // 正規化座標を計算 (0.0-1.0)
    vec2 uv = fragCoord / iResolution.xy;
    
    // 中心を原点とした座標系 (-1.0 to 1.0)
    vec2 p = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
    
    // 時間による色の変化
    vec3 col = 0.5 + 0.5 * cos(iTime + uv.xyx + vec3(0, 2, 4));
    
    // 中心からの距離による効果
    float dist = length(p);
    col *= 1.0 - smoothstep(0.0, 1.0, dist);
    
    // 波紋効果
    float ripple = sin(dist * 20.0 - iTime * 5.0) * 0.1;
    col += ripple;
    
    fragColor = vec4(col, 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 fragColor;
    mainImage(fragColor, screen_coords);
    return fragColor;
}]]
end

---@brief テキスト設定
---@param newText string 新しいテキスト
function Editor:setText(newText)
    self.text = newText or ""
    self.lines = {}
    
    for line in (self.text .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(self.lines, line)
    end
    
    if #self.lines == 0 then
        self.lines = {""}
    end
    
    self.cursorLine = math.min(self.cursorLine, #self.lines)
    self.cursorColumn = math.min(self.cursorColumn, #self.lines[self.cursorLine] + 1)
    
    self:updateText()
end

---@brief テキスト取得
---@return string 現在のテキスト
function Editor:getText()
    return self.text
end

---@brief テキスト更新
function Editor:updateText()
    self.text = table.concat(self.lines, "\n")
end

---@brief エディタ更新
---@param dt number デルタタイム
function Editor:update(dt)
end

---@brief エディタ描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function Editor:draw(x, y, width, height)
    local lineNumberWidth = 50
    local textAreaX = x + lineNumberWidth
    local textAreaWidth = width - lineNumberWidth
    
    love.graphics.setColor(COLORS.bg_primary)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(COLORS.bg_secondary)
    love.graphics.rectangle("fill", x, y, lineNumberWidth, height)
    
    love.graphics.setColor(COLORS.border)
    love.graphics.rectangle("line", x, y, width, height)
    love.graphics.line(x + lineNumberWidth, y, x + lineNumberWidth, y + height)
    
    local visibleLines = math.floor(height / self.lineHeight)
    local startLine = math.max(1, self.scrollOffset + 1)
    local endLine = math.min(#self.lines, startLine + visibleLines)
    
    love.graphics.setFont(self.font)
    
    for i = startLine, endLine do
        local lineY = y + (i - startLine) * self.lineHeight + 4
        
        if lineY + self.lineHeight > y + height then
            break
        end
        
        love.graphics.setColor(COLORS.text_disabled)
        love.graphics.printf(tostring(i), x + 4, lineY, lineNumberWidth - 8, "right")
        
        local line = self.lines[i] or ""
        love.graphics.setColor(COLORS.text_primary)
        love.graphics.print(line, textAreaX + 8, lineY)
        
        if i == self.cursorLine and self.isActive then
            local cursorX = textAreaX + 8 + self.font:getWidth(line:sub(1, self.cursorColumn - 1))
            love.graphics.setColor(COLORS.accent_primary)
            love.graphics.rectangle("fill", cursorX, lineY, 2, self.lineHeight - 2)
        end
    end
    
    love.graphics.setColor(COLORS.text_secondary)
    love.graphics.printf(
        string.format("行: %d, 列: %d | 行数: %d", self.cursorLine, self.cursorColumn, #self.lines),
        x, y + height - 20, width, "center"
    )
end

---@brief キー押下処理
---@param key string キー名
function Editor:keypressed(key)
    if key == "up" then
        self:moveCursor(0, -1)
    elseif key == "down" then
        self:moveCursor(0, 1)
    elseif key == "left" then
        self:moveCursor(-1, 0)
    elseif key == "right" then
        self:moveCursor(1, 0)
    elseif key == "home" then
        self.cursorColumn = 1
    elseif key == "end" then
        self.cursorColumn = #self.lines[self.cursorLine] + 1
    elseif key == "pageup" then
        self:moveCursor(0, -10)
    elseif key == "pagedown" then
        self:moveCursor(0, 10)
    elseif key == "backspace" then
        self:deleteCharacter()
    elseif key == "delete" then
        self:deleteCharacterForward()
    elseif key == "return" or key == "enter" then
        self:insertNewLine()
    elseif key == "tab" then
        self:insertText("    ")
    end
    
    self:ensureCursorVisible()
end

---@brief テキスト入力処理
---@param text string 入力テキスト
function Editor:textinput(text)
    if text and text ~= "" then
        self:insertText(text)
    end
end

---@brief カーソル移動
---@param deltaColumn number 列の移動量
---@param deltaLine number 行の移動量
function Editor:moveCursor(deltaColumn, deltaLine)
    if deltaLine ~= 0 then
        self.cursorLine = math.max(1, math.min(#self.lines, self.cursorLine + deltaLine))
        self.cursorColumn = math.min(self.cursorColumn, #self.lines[self.cursorLine] + 1)
    end
    
    if deltaColumn ~= 0 then
        local newColumn = self.cursorColumn + deltaColumn
        
        if newColumn < 1 and self.cursorLine > 1 then
            self.cursorLine = self.cursorLine - 1
            self.cursorColumn = #self.lines[self.cursorLine] + 1
        elseif newColumn > #self.lines[self.cursorLine] + 1 and self.cursorLine < #self.lines then
            self.cursorLine = self.cursorLine + 1
            self.cursorColumn = 1
        else
            self.cursorColumn = math.max(1, math.min(#self.lines[self.cursorLine] + 1, newColumn))
        end
    end
end

---@brief テキスト挿入
---@param text string 挿入するテキスト
function Editor:insertText(text)
    local line = self.lines[self.cursorLine]
    local before = line:sub(1, self.cursorColumn - 1)
    local after = line:sub(self.cursorColumn)
    
    self.lines[self.cursorLine] = before .. text .. after
    self.cursorColumn = self.cursorColumn + #text
    
    self:updateText()
end

---@brief 改行挿入
function Editor:insertNewLine()
    local line = self.lines[self.cursorLine]
    local before = line:sub(1, self.cursorColumn - 1)
    local after = line:sub(self.cursorColumn)
    
    self.lines[self.cursorLine] = before
    table.insert(self.lines, self.cursorLine + 1, after)
    
    self.cursorLine = self.cursorLine + 1
    self.cursorColumn = 1
    
    self:updateText()
end

---@brief 文字削除（後方）
function Editor:deleteCharacter()
    if self.cursorColumn > 1 then
        local line = self.lines[self.cursorLine]
        local before = line:sub(1, self.cursorColumn - 2)
        local after = line:sub(self.cursorColumn)
        
        self.lines[self.cursorLine] = before .. after
        self.cursorColumn = self.cursorColumn - 1
    elseif self.cursorLine > 1 then
        local currentLine = self.lines[self.cursorLine]
        local previousLine = self.lines[self.cursorLine - 1]
        
        self.lines[self.cursorLine - 1] = previousLine .. currentLine
        table.remove(self.lines, self.cursorLine)
        
        self.cursorLine = self.cursorLine - 1
        self.cursorColumn = #previousLine + 1
    end
    
    self:updateText()
end

---@brief 文字削除（前方）
function Editor:deleteCharacterForward()
    local line = self.lines[self.cursorLine]
    
    if self.cursorColumn <= #line then
        local before = line:sub(1, self.cursorColumn - 1)
        local after = line:sub(self.cursorColumn + 1)
        
        self.lines[self.cursorLine] = before .. after
    elseif self.cursorLine < #self.lines then
        local currentLine = self.lines[self.cursorLine]
        local nextLine = self.lines[self.cursorLine + 1]
        
        self.lines[self.cursorLine] = currentLine .. nextLine
        table.remove(self.lines, self.cursorLine + 1)
    end
    
    self:updateText()
end

---@brief カーソル可視化確保
function Editor:ensureCursorVisible()
    local visibleLines = 20
    
    if self.cursorLine - 1 < self.scrollOffset then
        self.scrollOffset = self.cursorLine - 1
    elseif self.cursorLine - 1 >= self.scrollOffset + visibleLines then
        self.scrollOffset = self.cursorLine - visibleLines
    end
    
    self.scrollOffset = math.max(0, self.scrollOffset)
end

---@brief マウス押下処理
---@param x number マウスX座標
---@param y number マウスY座標
function Editor:mousepressed(x, y)
    self.isActive = true
end

---@brief アクティブ状態取得
---@return boolean アクティブ状態
function Editor:isEditorActive()
    return self.isActive
end

---@brief アクティブ状態設定
---@param active boolean アクティブ状態
function Editor:setActive(active)
    self.isActive = active
end

return Editor