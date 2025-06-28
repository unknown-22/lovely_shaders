---@file ui/uniform_panel.lua
---@brief カスタムUniform変数パネル
---@details スライダー、カラーピッカーによるUniform変数調整GUI

local Components = require("ui.components")

---@class UniformPanel
---@field uniformManager UniformManager Uniform変数管理
---@field components Components UIコンポーネント
---@field scrollY number スクロール位置
---@field selectedUniform string|nil 選択中のUniform変数
---@field showAddDialog boolean 追加ダイアログ表示フラグ
---@field addDialogType string 追加ダイアログの型
---@field addDialogName string 追加ダイアログの名前
---@field addDialogValue table 追加ダイアログの値
---@field addDialogMin number 追加ダイアログの最小値
---@field addDialogMax number 追加ダイアログの最大値
---@field nameInputFocused boolean 名前入力フィールドのフォーカス状態
local UniformPanel = {}
UniformPanel.__index = UniformPanel

local BUTTON_HEIGHT = 24
local SLIDER_HEIGHT = 20
local ITEM_MARGIN = 8
local PANEL_PADDING = 8

---@brief UniformPanelコンストラクタ
---@param uniformManager UniformManager Uniform変数管理
---@return UniformPanel
function UniformPanel.new(uniformManager)
    local self = setmetatable({}, UniformPanel)
    self.uniformManager = uniformManager
    self.components = Components.new()
    self.scrollY = 0
    self.selectedUniform = nil
    self.showAddDialog = false
    self.addDialogType = "float"
    self.addDialogName = ""
    self.addDialogValue = {0.0, 0.0, 0.0, 1.0}
    self.addDialogMin = 0.0
    self.addDialogMax = 1.0
    self.nameInputFocused = false
    return self
end

---@brief パネル描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function UniformPanel:draw(x, y, width, height)
    -- 背景
    love.graphics.setColor(0.12, 0.12, 0.14, 1.0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- ヘッダー
    love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
    love.graphics.rectangle("fill", x, y, width, 32)
    
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print("カスタムUniform変数", x + PANEL_PADDING, y + 8)
    
    -- 追加ボタン
    local addButtonX = x + width - 60 - PANEL_PADDING
    if self.components:drawButton(addButtonX, y + 4, 60, 24, "追加", function()
        self.showAddDialog = true
        self.addDialogName = ""
        self.addDialogType = "float"
        self.addDialogValue = {0.0, 0.0, 0.0, 1.0}
        self.addDialogMin = 0.0
        self.addDialogMax = 1.0
        self.nameInputFocused = true
    end) then
        -- クリック処理は関数内で実行される
    end
    
    -- スクロール可能エリア
    local contentY = y + 32
    local contentHeight = height - 32
    
    love.graphics.setScissor(x, contentY, width, contentHeight)
    
    local currentY = contentY + PANEL_PADDING - self.scrollY
    local uniforms = self.uniformManager:getAllUniforms()
    
    -- Uniform変数がない場合のメッセージ
    if next(uniforms) == nil then
        love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
        love.graphics.print("Uniform変数が登録されていません", x + PANEL_PADDING, currentY)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setScissor()
        
        -- 追加ダイアログ
        if self.showAddDialog then
            self:drawAddDialog()
        end
        return
    end
    
    -- Uniform変数リスト描画
    for name, uniform in pairs(uniforms) do
        if currentY + self:getUniformItemHeight(uniform) > contentY and currentY < contentY + contentHeight then
            self:drawUniformItem(name, uniform, x + PANEL_PADDING, currentY, width - PANEL_PADDING * 2)
        end
        currentY = currentY + self:getUniformItemHeight(uniform) + ITEM_MARGIN
    end
    
    love.graphics.setScissor()
    
    -- 追加ダイアログ
    if self.showAddDialog then
        self:drawAddDialog()
    end
end

---@brief Uniform変数アイテムの高さを取得
---@param uniform UniformParam Uniform変数
---@return number 高さ
function UniformPanel:getUniformItemHeight(uniform)
    if uniform.type == "float" then
        return BUTTON_HEIGHT + SLIDER_HEIGHT + ITEM_MARGIN
    elseif uniform.type == "vec2" then
        return BUTTON_HEIGHT + SLIDER_HEIGHT * 2 + ITEM_MARGIN
    elseif uniform.type == "vec3" then
        return BUTTON_HEIGHT + SLIDER_HEIGHT * 3 + ITEM_MARGIN
    elseif uniform.type == "vec4" then
        return BUTTON_HEIGHT + SLIDER_HEIGHT * 4 + ITEM_MARGIN
    end
    return BUTTON_HEIGHT
end

---@brief Uniform変数アイテム描画
---@param name string 変数名
---@param uniform UniformParam Uniform変数
---@param x number X座標
---@param y number Y座標
---@param width number 幅
function UniformPanel:drawUniformItem(name, uniform, x, y, width)
    -- 背景
    love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
    love.graphics.rectangle("fill", x, y, width, self:getUniformItemHeight(uniform))
    
    -- 名前と削除ボタン
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print(string.format("%s (%s)", name, uniform.type), x + 4, y + 4)
    
    local deleteButtonX = x + width - 50
    if self.components:drawButton(deleteButtonX, y + 2, 48, 20, "削除", function()
        self.uniformManager:removeUniform(name)
    end) then
        -- クリック処理は関数内で実行される
    end
    
    local sliderY = y + BUTTON_HEIGHT + 2
    local sliderWidth = width - 8
    
    -- 型に応じてスライダーを描画
    if uniform.type == "float" then
        local newValue = self:drawSlider(x + 4, sliderY, sliderWidth, uniform.value, uniform.min, uniform.max, name, nil)
        if newValue ~= uniform.value then
            self.uniformManager:setValue(name, newValue)
        end
    elseif uniform.type == "vec2" then
        local components = {"X", "Y"}
        for i = 1, 2 do
            local newValue = self:drawSlider(
                x + 4, sliderY + (i - 1) * SLIDER_HEIGHT, sliderWidth,
                uniform.value[i], uniform.min, uniform.max,
                name .. "_" .. i, components[i]
            )
            if newValue ~= uniform.value[i] then
                local newVec = {uniform.value[1], uniform.value[2]}
                newVec[i] = newValue
                self.uniformManager:setValue(name, newVec)
            end
        end
    elseif uniform.type == "vec3" then
        local components = {"X", "Y", "Z"}
        for i = 1, 3 do
            local newValue = self:drawSlider(
                x + 4, sliderY + (i - 1) * SLIDER_HEIGHT, sliderWidth,
                uniform.value[i], uniform.min, uniform.max,
                name .. "_" .. i, components[i]
            )
            if newValue ~= uniform.value[i] then
                local newVec = {uniform.value[1], uniform.value[2], uniform.value[3]}
                newVec[i] = newValue
                self.uniformManager:setValue(name, newVec)
            end
        end
    elseif uniform.type == "vec4" then
        local components = {"X", "Y", "Z", "W"}
        for i = 1, 4 do
            local newValue = self:drawSlider(
                x + 4, sliderY + (i - 1) * SLIDER_HEIGHT, sliderWidth,
                uniform.value[i], uniform.min, uniform.max,
                name .. "_" .. i, components[i]
            )
            if newValue ~= uniform.value[i] then
                local newVec = {uniform.value[1], uniform.value[2], uniform.value[3], uniform.value[4]}
                newVec[i] = newValue
                self.uniformManager:setValue(name, newVec)
            end
        end
    end
end

---@brief スライダー描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param value number 現在値
---@param minValue number 最小値
---@param maxValue number 最大値
---@param id string ID
---@param label string ラベル
---@return number 新しい値
function UniformPanel:drawSlider(x, y, width, value, minValue, maxValue, id, label)
    local trackHeight = 4
    local handleSize = 12
    local labelWidth = 20
    
    -- ラベル
    if label then
        love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
        love.graphics.print(label, x, y)
    end
    
    local sliderX = x + labelWidth
    local sliderWidth = width - labelWidth - 60
    local valueX = sliderX + sliderWidth + 4
    
    -- トラック
    love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
    love.graphics.rectangle("fill", sliderX, y + (SLIDER_HEIGHT - trackHeight) / 2, sliderWidth, trackHeight)
    
    -- ハンドル位置計算
    local normalizedValue = (value - minValue) / (maxValue - minValue)
    local handleX = sliderX + normalizedValue * (sliderWidth - handleSize)
    
    -- ハンドル
    love.graphics.setColor(0.33, 0.60, 0.99, 1.0)
    love.graphics.rectangle("fill", handleX, y + (SLIDER_HEIGHT - handleSize) / 2, handleSize, handleSize)
    
    -- 値表示
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print(string.format("%.2f", value), valueX, y)
    
    -- マウス処理（簡易版）
    local mx, my = love.mouse.getPosition()
    if love.mouse.isDown(1) and mx >= sliderX and mx <= sliderX + sliderWidth and my >= y and my <= y + SLIDER_HEIGHT then
        local newNormalizedValue = (mx - sliderX) / sliderWidth
        newNormalizedValue = math.max(0, math.min(1, newNormalizedValue))
        return minValue + newNormalizedValue * (maxValue - minValue)
    end
    
    return value
end

---@brief 追加ダイアログ描画
function UniformPanel:drawAddDialog()
    local width, height = love.graphics.getDimensions()
    local dialogWidth = 400
    local dialogHeight = 300
    local dialogX = (width - dialogWidth) / 2
    local dialogY = (height - dialogHeight) / 2
    
    -- 背景オーバーレイ
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- ダイアログ背景
    love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
    love.graphics.rectangle("fill", dialogX, dialogY, dialogWidth, dialogHeight)
    
    -- ヘッダー
    love.graphics.setColor(0.12, 0.12, 0.14, 1.0)
    love.graphics.rectangle("fill", dialogX, dialogY, dialogWidth, 32)
    
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print("Uniform変数を追加", dialogX + 8, dialogY + 8)
    
    local currentY = dialogY + 40
    
    -- 名前入力
    love.graphics.print("名前:", dialogX + 8, currentY)
    
    -- 名前入力フィールド
    local inputX = dialogX + 60
    local inputY = currentY - 2
    local inputWidth = 200
    local inputHeight = 20
    
    -- フォーカス状態に応じて色を変更
    if self.nameInputFocused then
        love.graphics.setColor(0.33, 0.60, 0.99, 0.3)
    else
        love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
    end
    love.graphics.rectangle("fill", inputX, inputY, inputWidth, inputHeight)
    
    -- ボーダー
    if self.nameInputFocused then
        love.graphics.setColor(0.33, 0.60, 0.99, 1.0)
    else
        love.graphics.setColor(0.40, 0.40, 0.43, 1.0)
    end
    love.graphics.rectangle("line", inputX, inputY, inputWidth, inputHeight)
    
    -- テキスト表示
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print(self.addDialogName, inputX + 5, currentY)
    
    -- カーソル表示（フォーカス時）
    if self.nameInputFocused then
        local textWidth = love.graphics.getFont():getWidth(self.addDialogName)
        love.graphics.setColor(0.95, 0.95, 0.96, 0.8)
        love.graphics.rectangle("fill", inputX + 5 + textWidth, currentY, 1, 14)
    end
    
    currentY = currentY + 30
    
    -- 型選択
    love.graphics.print("型:", dialogX + 8, currentY)
    local types = {"float", "vec2", "vec3", "vec4"}
    for i, typeName in ipairs(types) do
        local buttonX = dialogX + 60 + (i - 1) * 70
        local isSelected = self.addDialogType == typeName
        
        if isSelected then
            love.graphics.setColor(0.33, 0.60, 0.99, 1.0)
        else
            love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
        end
        love.graphics.rectangle("fill", buttonX, currentY - 2, 65, 20)
        
        love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
        love.graphics.print(typeName, buttonX + 5, currentY)
    end
    
    currentY = currentY + 30
    
    -- 範囲設定
    love.graphics.print("最小値:", dialogX + 8, currentY)
    love.graphics.print(string.format("%.2f", self.addDialogMin), dialogX + 60, currentY)
    
    currentY = currentY + 25
    love.graphics.print("最大値:", dialogX + 8, currentY)
    love.graphics.print(string.format("%.2f", self.addDialogMax), dialogX + 60, currentY)
    
    -- ボタン
    local buttonY = dialogY + dialogHeight - 40
    if self.components:drawButton(dialogX + dialogWidth - 160, buttonY, 70, 30, "追加", function()
        if self.addDialogName ~= "" then
            if self.addDialogType == "float" then
                self.uniformManager:addFloat(self.addDialogName, self.addDialogValue[1], self.addDialogMin, self.addDialogMax)
            elseif self.addDialogType == "vec2" then
                self.uniformManager:addVec2(self.addDialogName, {self.addDialogValue[1], self.addDialogValue[2]}, self.addDialogMin, self.addDialogMax)
            elseif self.addDialogType == "vec3" then
                self.uniformManager:addVec3(self.addDialogName, {self.addDialogValue[1], self.addDialogValue[2], self.addDialogValue[3]}, self.addDialogMin, self.addDialogMax)
            elseif self.addDialogType == "vec4" then
                self.uniformManager:addVec4(self.addDialogName, self.addDialogValue, self.addDialogMin, self.addDialogMax)
            end
            self.showAddDialog = false
            self.nameInputFocused = false
        end
    end) then
        -- クリック処理は関数内で実行される
    end
    
    if self.components:drawButton(dialogX + dialogWidth - 80, buttonY, 70, 30, "キャンセル", function()
        self.showAddDialog = false
    end) then
        -- クリック処理は関数内で実行される
    end
end

---@brief マウス処理
---@param x number マウスX座標
---@param y number マウスY座標
---@param panelX number パネルX座標
---@param panelY number パネルY座標
---@param panelWidth number パネル幅
---@param panelHeight number パネル高さ
function UniformPanel:mousepressed(x, y, panelX, panelY, panelWidth, panelHeight)
    if self.showAddDialog then
        local width, height = love.graphics.getDimensions()
        local dialogWidth = 400
        local dialogHeight = 300
        local dialogX = (width - dialogWidth) / 2
        local dialogY = (height - dialogHeight) / 2
        
        -- ダイアログ外をクリックした場合は閉じる
        if x < dialogX or x > dialogX + dialogWidth or y < dialogY or y > dialogY + dialogHeight then
            self.showAddDialog = false
            self.nameInputFocused = false
        else
            -- ダイアログ内のボタンクリック処理
            self.components:mousepressed(x, y)
            
            -- 名前入力フィールドのクリック処理
            local inputX = dialogX + 60
            local inputY = dialogY + 38
            local inputWidth = 200
            local inputHeight = 20
            
            if x >= inputX and x <= inputX + inputWidth and y >= inputY and y <= inputY + inputHeight then
                self.nameInputFocused = true
            else
                self.nameInputFocused = false
            end
            
            -- 型選択ボタン
            local buttonY = dialogY + 70
            local types = {"float", "vec2", "vec3", "vec4"}
            for i, typeName in ipairs(types) do
                local buttonX = dialogX + 60 + (i - 1) * 70
                if x >= buttonX and x <= buttonX + 65 and y >= buttonY - 2 and y <= buttonY + 18 then
                    self.addDialogType = typeName
                end
            end
        end
        return
    end
    
    -- パネル内のクリック処理
    if x >= panelX and x <= panelX + panelWidth and y >= panelY and y <= panelY + panelHeight then
        self.components:mousepressed(x, y)
    end
end

---@brief ホイール処理
---@param x number X方向スクロール
---@param y number Y方向スクロール
function UniformPanel:wheelmoved(x, y)
    if not self.showAddDialog then
        self.scrollY = math.max(0, self.scrollY - y * 20)
    end
end

---@brief テキスト入力処理
---@param text string 入力テキスト
function UniformPanel:textinput(text)
    if self.showAddDialog and self.nameInputFocused then
        -- 英数字、アンダースコアのみ許可
        if text:match("[%w_]") then
            self.addDialogName = self.addDialogName .. text
        end
    end
end

---@brief キー入力処理
---@param key string キー名
function UniformPanel:keypressed(key)
    if self.showAddDialog then
        if key == "backspace" and self.nameInputFocused and #self.addDialogName > 0 then
            self.addDialogName = self.addDialogName:sub(1, -2)
        elseif key == "escape" then
            self.showAddDialog = false
            self.nameInputFocused = false
            self.nameInputFocused = false
        end
    end
end

return UniformPanel