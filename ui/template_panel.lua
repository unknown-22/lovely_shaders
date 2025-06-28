---@file ui/template_panel.lua
---@brief テンプレート選択パネルUI
---@details シェーダーテンプレートを選択・適用するUIコンポーネント

---@class TemplatePanel
---@field templateManager TemplateManager テンプレートマネージャー参照
---@field selectedCategory string 選択中のカテゴリ
---@field selectedTemplate string|nil 選択中のテンプレート名
---@field visible boolean パネルの表示状態
---@field scrollOffset number スクロールオフセット
local TemplatePanel = {}
TemplatePanel.__index = TemplatePanel

---@brief 新しいTemplatePanelインスタンスを作成
---@param templateManager TemplateManager テンプレートマネージャー
---@return TemplatePanel
function TemplatePanel.new(templateManager)
    local self = setmetatable({}, TemplatePanel)
    
    self.templateManager = templateManager
    self.selectedCategory = "基本"
    self.selectedTemplate = nil
    self.visible = false
    self.scrollOffset = 0
    
    return self
end

---@brief パネルの表示状態を切り替え
function TemplatePanel:toggle()
    self.visible = not self.visible
end

---@brief パネルの表示状態を設定
---@param visible boolean 表示状態
function TemplatePanel:setVisible(visible)
    self.visible = visible
end

---@brief テンプレートパネルを描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function TemplatePanel:draw(x, y, width, height)
    if not self.visible then
        return
    end
    
    -- 背景
    love.graphics.setColor(0.09, 0.09, 0.11, 0.95)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- ボーダー
    love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- ヘッダー
    love.graphics.setColor(0.12, 0.12, 0.14, 1.0)
    love.graphics.rectangle("fill", x, y, width, 32)
    
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print("テンプレート選択", x + 8, y + 8)
    
    -- 閉じるボタン
    love.graphics.setColor(0.95, 0.26, 0.21, 1.0)
    love.graphics.rectangle("fill", x + width - 28, y + 4, 24, 24)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("×", x + width - 28, y + 8, 24, "center")
    
    -- カテゴリタブ
    local categories = self.templateManager:getCategories()
    local tabY = y + 40
    local tabWidth = math.floor((width - 16) / #categories)
    
    for i, category in ipairs(categories) do
        local tabX = x + 8 + (i - 1) * tabWidth
        local isSelected = self.selectedCategory == category
        
        if isSelected then
            love.graphics.setColor(0.33, 0.60, 0.99, 1.0)
        else
            love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
        end
        
        love.graphics.rectangle("fill", tabX, tabY, tabWidth - 2, 28)
        
        love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
        love.graphics.printf(category, tabX, tabY + 7, tabWidth - 2, "center")
    end
    
    -- テンプレートリスト
    local listY = tabY + 36
    local listHeight = height - (listY - y) - 8
    local templates = self.templateManager:getTemplatesByCategory(self.selectedCategory)
    
    love.graphics.setScissor(x, listY, width, listHeight)
    
    local itemHeight = 60
    local currentY = listY - self.scrollOffset
    
    for i, template in ipairs(templates) do
        local itemY = currentY + (i - 1) * itemHeight
        
        if itemY + itemHeight >= listY and itemY <= listY + listHeight then
            local isSelected = self.selectedTemplate == template.name
            
            -- アイテム背景
            if isSelected then
                love.graphics.setColor(0.33, 0.60, 0.99, 0.3)
            elseif i % 2 == 0 then
                love.graphics.setColor(0.12, 0.12, 0.14, 1.0)
            else
                love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
            end
            
            love.graphics.rectangle("fill", x + 8, itemY, width - 16, itemHeight - 2)
            
            -- テンプレート名
            love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
            love.graphics.print(template.name, x + 16, itemY + 8)
            
            -- 説明
            love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
            love.graphics.print(template.description, x + 16, itemY + 28)
            
            -- 適用ボタン
            local buttonX = x + width - 80
            local buttonY = itemY + 16
            
            love.graphics.setColor(0.33, 0.60, 0.99, 1.0)
            love.graphics.rectangle("fill", buttonX, buttonY, 64, 28)
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf("適用", buttonX, buttonY + 7, 64, "center")
        end
    end
    
    love.graphics.setScissor()
    
    -- スクロールバー
    if #templates * itemHeight > listHeight then
        local scrollbarWidth = 8
        local scrollbarX = x + width - scrollbarWidth - 4
        local scrollbarHeight = listHeight * (listHeight / (#templates * itemHeight))
        local scrollbarY = listY + (self.scrollOffset / (#templates * itemHeight - listHeight)) * (listHeight - scrollbarHeight)
        
        love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
        love.graphics.rectangle("fill", scrollbarX, listY, scrollbarWidth, listHeight)
        
        love.graphics.setColor(0.40, 0.40, 0.43, 1.0)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight)
    end
end

---@brief マウスクリック処理
---@param mx number マウスX座標
---@param my number マウスY座標
---@param panelX number パネルX座標
---@param panelY number パネルY座標
---@param panelWidth number パネル幅
---@param panelHeight number パネル高さ
---@return string|nil 選択されたテンプレートのコード（または nil）
function TemplatePanel:mousepressed(mx, my, panelX, panelY, panelWidth, panelHeight)
    if not self.visible then
        return nil
    end
    
    -- 閉じるボタン
    if mx >= panelX + panelWidth - 28 and mx <= panelX + panelWidth - 4 and
       my >= panelY + 4 and my <= panelY + 28 then
        self.visible = false
        return nil
    end
    
    -- カテゴリタブ
    local categories = self.templateManager:getCategories()
    local tabY = panelY + 40
    local tabWidth = math.floor((panelWidth - 16) / #categories)
    
    for i, category in ipairs(categories) do
        local tabX = panelX + 8 + (i - 1) * tabWidth
        if mx >= tabX and mx <= tabX + tabWidth - 2 and my >= tabY and my <= tabY + 28 then
            self.selectedCategory = category
            self.scrollOffset = 0
            return nil
        end
    end
    
    -- テンプレートリスト
    local listY = tabY + 36
    local listHeight = panelHeight - (listY - panelY) - 8
    local templates = self.templateManager:getTemplatesByCategory(self.selectedCategory)
    
    if mx >= panelX and mx <= panelX + panelWidth and my >= listY and my <= listY + listHeight then
        local itemHeight = 60
        local relativeY = my - listY + self.scrollOffset
        local itemIndex = math.floor(relativeY / itemHeight) + 1
        
        if itemIndex >= 1 and itemIndex <= #templates then
            local template = templates[itemIndex]
            self.selectedTemplate = template.name
            
            -- 適用ボタンのクリック判定
            local buttonX = panelX + panelWidth - 80
            local itemY = listY + (itemIndex - 1) * itemHeight - self.scrollOffset
            local buttonY = itemY + 16
            
            if mx >= buttonX and mx <= buttonX + 64 and my >= buttonY and my <= buttonY + 28 then
                print("[TemplatePanel] テンプレートを適用: " .. template.name)
                self.visible = false
                return template.code
            end
        end
    end
    
    return nil
end

---@brief マウスホイール処理
---@param dx number X方向のスクロール
---@param dy number Y方向のスクロール
function TemplatePanel:wheelmoved(dx, dy)
    if not self.visible then
        return
    end
    
    local templates = self.templateManager:getTemplatesByCategory(self.selectedCategory)
    local maxScroll = math.max(0, #templates * 60 - 300) -- 300はリスト表示領域の高さ
    
    self.scrollOffset = math.max(0, math.min(maxScroll, self.scrollOffset - dy * 30))
end

---@brief パネルが表示中かどうか
---@return boolean 表示状態
function TemplatePanel:isVisible()
    return self.visible
end

return TemplatePanel