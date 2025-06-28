---@file core/template_manager.lua
---@brief テンプレート管理モジュール
---@details シェーダーテンプレートとプリセットを管理

---@class Template
---@field name string テンプレート名
---@field description string 説明
---@field code string シェーダーコード
---@field category string カテゴリ

---@class TemplateManager
---@field templates Template[] テンプレート配列
local TemplateManager = {}
TemplateManager.__index = TemplateManager

---@brief 新しいTemplateManagerインスタンスを作成
---@return TemplateManager
function TemplateManager.new()
    local self = setmetatable({}, TemplateManager)
    
    self.templates = {}
    self:loadTemplatesFromFiles()
    
    return self
end

---@brief テンプレートファイルから読み込む
function TemplateManager:loadTemplatesFromFiles()
    -- テンプレート設定を読み込み
    local success, templateConfigs = pcall(require, "templates.templates")
    if not success then
        print("[TemplateManager] テンプレート設定ファイルが読み込めません: " .. tostring(templateConfigs))
        return
    end
    
    for _, config in ipairs(templateConfigs) do
        local templatePath = "templates/" .. config.file
        local codeSuccess, code = pcall(love.filesystem.read, templatePath)
        
        if codeSuccess and code then
            -- FileDataから文字列へ変換（必要な場合）
            if type(code) == "userdata" and code.getString then
                code = code:getString()
            end
            
            table.insert(self.templates, {
                name = config.name,
                description = config.description,
                category = config.category,
                code = code
            })
            
            print(string.format("[TemplateManager] テンプレート読み込み成功: %s", config.name))
        else
            print(string.format("[TemplateManager] テンプレートファイル読み込み失敗: %s - %s", templatePath, tostring(code)))
        end
    end
    
    print(string.format("[TemplateManager] %d個のテンプレートを読み込みました", #self.templates))
end

---@brief テンプレート一覧を取得
---@return Template[]
function TemplateManager:getTemplates()
    return self.templates
end

---@brief カテゴリ別テンプレート取得
---@param category string カテゴリ名
---@return Template[]
function TemplateManager:getTemplatesByCategory(category)
    local filtered = {}
    for _, template in ipairs(self.templates) do
        if template.category == category then
            table.insert(filtered, template)
        end
    end
    return filtered
end

---@brief テンプレートを名前で取得
---@param name string テンプレート名
---@return Template|nil
function TemplateManager:getTemplateByName(name)
    for _, template in ipairs(self.templates) do
        if template.name == name then
            return template
        end
    end
    return nil
end

---@brief カテゴリ一覧を取得
---@return string[]
function TemplateManager:getCategories()
    local categories = {}
    local seen = {}
    
    for _, template in ipairs(self.templates) do
        if not seen[template.category] then
            table.insert(categories, template.category)
            seen[template.category] = true
        end
    end
    
    return categories
end

---@brief カスタムテンプレートを追加
---@param name string テンプレート名
---@param description string 説明
---@param category string カテゴリ
---@param code string シェーダーコード
---@return boolean 成功フラグ
function TemplateManager:addTemplate(name, description, category, code)
    -- 重複チェック
    if self:getTemplateByName(name) then
        print("[TemplateManager] テンプレート名が重複しています: " .. name)
        return false
    end
    
    table.insert(self.templates, {
        name = name,
        description = description,
        category = category,
        code = code
    })
    
    print("[TemplateManager] テンプレートを追加しました: " .. name)
    return true
end

---@brief テンプレートを削除
---@param name string テンプレート名
---@return boolean 成功フラグ
function TemplateManager:removeTemplate(name)
    for i, template in ipairs(self.templates) do
        if template.name == name then
            table.remove(self.templates, i)
            print("[TemplateManager] テンプレートを削除しました: " .. name)
            return true
        end
    end
    
    print("[TemplateManager] テンプレートが見つかりません: " .. name)
    return false
end

---@brief テンプレートを再読み込み
function TemplateManager:reload()
    self.templates = {}
    self:loadTemplatesFromFiles()
end

return TemplateManager