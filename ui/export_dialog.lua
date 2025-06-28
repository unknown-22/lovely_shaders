---@file ui/export_dialog.lua
---@brief 画像エクスポートダイアログUI
---@details シェーダーを画像として出力するためのダイアログ

---@class ExportDialog
---@field exportManager ExportManager エクスポートマネージャー参照
---@field visible boolean ダイアログの表示状態
---@field selectedPreset string 選択中のプリセット
---@field customWidth number カスタム幅
---@field customHeight number カスタム高さ
---@field filename string ファイル名
---@field useCustomSize boolean カスタムサイズを使用するか
local ExportDialog = {}
ExportDialog.__index = ExportDialog

---@brief 新しいExportDialogインスタンスを作成
---@param exportManager ExportManager エクスポートマネージャー
---@return ExportDialog
function ExportDialog.new(exportManager)
    local self = setmetatable({}, ExportDialog)
    
    self.exportManager = exportManager
    self.visible = false
    self.selectedPreset = "FHD"
    self.customWidth = 1920
    self.customHeight = 1080
    self.filename = ""
    self.useCustomSize = false
    
    return self
end

---@brief ダイアログの表示状態を切り替え
function ExportDialog:toggle()
    self.visible = not self.visible
    if self.visible then
        -- デフォルトのファイル名を生成
        local timestamp = os.date("%Y%m%d_%H%M%S")
        self.filename = string.format("shader_export_%s", timestamp)
    end
end

---@brief ダイアログの表示状態を設定
---@param visible boolean 表示状態
function ExportDialog:setVisible(visible)
    self.visible = visible
end

---@brief エクスポートダイアログを描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function ExportDialog:draw(x, y, width, height)
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
    love.graphics.print("画像エクスポート", x + 8, y + 8)
    
    -- 閉じるボタン
    love.graphics.setColor(0.95, 0.26, 0.21, 1.0)
    love.graphics.rectangle("fill", x + width - 28, y + 4, 24, 24)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("×", x + width - 28, y + 8, 24, "center")
    
    local contentY = y + 48
    
    -- ファイル名入力
    love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
    love.graphics.print("ファイル名:", x + 16, contentY)
    
    love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
    love.graphics.rectangle("fill", x + 16, contentY + 20, width - 120, 28)
    love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
    love.graphics.rectangle("line", x + 16, contentY + 20, width - 120, 28)
    
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print(self.filename, x + 24, contentY + 27)
    love.graphics.print(".png", x + width - 96, contentY + 27)
    
    -- 解像度設定
    contentY = contentY + 64
    love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
    love.graphics.print("解像度:", x + 16, contentY)
    
    -- プリセットボタン
    local presets = {"HD", "FHD", "4K", "カスタム"}
    local buttonWidth = 80
    local buttonHeight = 28
    local buttonSpacing = 8
    
    for i, preset in ipairs(presets) do
        local buttonX = x + 16 + (i - 1) * (buttonWidth + buttonSpacing)
        local buttonY = contentY + 20
        
        local isSelected = (preset == "カスタム" and self.useCustomSize) or 
                          (preset ~= "カスタム" and not self.useCustomSize and self.selectedPreset == preset)
        
        if isSelected then
            love.graphics.setColor(0.33, 0.60, 0.99, 1.0)
        else
            love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
        end
        
        love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight)
        love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
        love.graphics.rectangle("line", buttonX, buttonY, buttonWidth, buttonHeight)
        
        love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
        love.graphics.printf(preset, buttonX, buttonY + 7, buttonWidth, "center")
    end
    
    -- 解像度表示/カスタム入力
    contentY = contentY + 64
    if self.useCustomSize then
        love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
        love.graphics.print("幅:", x + 16, contentY)
        
        love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
        love.graphics.rectangle("fill", x + 50, contentY - 3, 100, 28)
        love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
        love.graphics.rectangle("line", x + 50, contentY - 3, 100, 28)
        
        love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
        love.graphics.print(tostring(self.customWidth), x + 58, contentY + 4)
        
        love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
        love.graphics.print("高さ:", x + 170, contentY)
        
        love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
        love.graphics.rectangle("fill", x + 210, contentY - 3, 100, 28)
        love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
        love.graphics.rectangle("line", x + 210, contentY - 3, 100, 28)
        
        love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
        love.graphics.print(tostring(self.customHeight), x + 218, contentY + 4)
    else
        local resolutions = {
            HD = "1280 × 720",
            FHD = "1920 × 1080",
            ["4K"] = "3840 × 2160"
        }
        
        love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
        love.graphics.print("解像度: " .. (resolutions[self.selectedPreset] or "不明"), x + 16, contentY)
    end
    
    -- エクスポートボタン
    local exportButtonY = y + height - 48
    love.graphics.setColor(0.30, 0.69, 0.31, 1.0)
    love.graphics.rectangle("fill", x + width - 120, exportButtonY, 100, 32)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("エクスポート", x + width - 120, exportButtonY + 9, 100, "center")
    
    -- キャンセルボタン
    love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
    love.graphics.rectangle("fill", x + width - 240, exportButtonY, 100, 32)
    love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
    love.graphics.rectangle("line", x + width - 240, exportButtonY, 100, 32)
    
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.printf("キャンセル", x + width - 240, exportButtonY + 9, 100, "center")
    
    -- エクスポート先パス表示
    love.graphics.setColor(0.40, 0.40, 0.44, 1.0)
    local exportPath = self.exportManager:getExportDirectory()
    love.graphics.print("保存先: " .. exportPath, x + 16, exportButtonY + 8)
end

---@brief マウスクリック処理
---@param mx number マウスX座標
---@param my number マウスY座標
---@param dialogX number ダイアログX座標
---@param dialogY number ダイアログY座標
---@param dialogWidth number ダイアログ幅
---@param dialogHeight number ダイアログ高さ
---@return boolean エクスポートが実行されたかどうか
function ExportDialog:mousepressed(mx, my, dialogX, dialogY, dialogWidth, dialogHeight)
    if not self.visible then
        return false
    end
    
    -- 閉じるボタン
    if mx >= dialogX + dialogWidth - 28 and mx <= dialogX + dialogWidth - 4 and
       my >= dialogY + 4 and my <= dialogY + 28 then
        self.visible = false
        return false
    end
    
    local contentY = dialogY + 48 + 64
    
    -- プリセットボタン
    local presets = {"HD", "FHD", "4K", "カスタム"}
    local buttonWidth = 80
    local buttonHeight = 28
    local buttonSpacing = 8
    
    for i, preset in ipairs(presets) do
        local buttonX = dialogX + 16 + (i - 1) * (buttonWidth + buttonSpacing)
        local buttonY = contentY + 20
        
        if mx >= buttonX and mx <= buttonX + buttonWidth and
           my >= buttonY and my <= buttonY + buttonHeight then
            if preset == "カスタム" then
                self.useCustomSize = true
            else
                self.useCustomSize = false
                self.selectedPreset = preset
            end
            return false
        end
    end
    
    -- エクスポートボタン
    local exportButtonY = dialogY + dialogHeight - 48
    if mx >= dialogX + dialogWidth - 120 and mx <= dialogX + dialogWidth - 20 and
       my >= exportButtonY and my <= exportButtonY + 32 then
        return self:performExport()
    end
    
    -- キャンセルボタン
    if mx >= dialogX + dialogWidth - 240 and mx <= dialogX + dialogWidth - 140 and
       my >= exportButtonY and my <= exportButtonY + 32 then
        self.visible = false
        return false
    end
    
    return false
end

---@brief エクスポートを実行
---@return boolean 成功フラグ
function ExportDialog:performExport()
    local width, height
    
    if self.useCustomSize then
        width = self.customWidth
        height = self.customHeight
    else
        local resolutions = {
            HD = {1280, 720},
            FHD = {1920, 1080},
            ["4K"] = {3840, 2160}
        }
        local resolution = resolutions[self.selectedPreset]
        if not resolution then
            print("[ExportDialog] 無効なプリセット: " .. self.selectedPreset)
            return false
        end
        width = resolution[1]
        height = resolution[2]
    end
    
    -- 設定の検証
    local valid, errorMsg = self.exportManager:validateExportSettings(width, height)
    if not valid then
        print("[ExportDialog] エクスポート設定エラー: " .. errorMsg)
        return false
    end
    
    -- エクスポート実行
    local success = self.exportManager:exportImage(width, height, self.filename)
    
    if success then
        self.visible = false
    end
    
    return success
end

---@brief ダイアログが表示中かどうか
---@return boolean 表示状態
function ExportDialog:isVisible()
    return self.visible
end

return ExportDialog