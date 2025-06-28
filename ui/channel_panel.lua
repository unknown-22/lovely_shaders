---@file ui/channel_panel.lua
---@brief チャンネル設定パネルUI
---@details シェーダーの入力チャンネル設定を管理するUIコンポーネント

local Components = require("ui.components")

---@class ChannelPanel
---@field channelManager ChannelManager チャンネルマネージャー参照
---@field components Components UIコンポーネント
---@field selectedChannel number 選択中のチャンネル（1-4）
---@field dropdownOpen boolean[] ドロップダウンの開閉状態
local ChannelPanel = {}
ChannelPanel.__index = ChannelPanel

---@brief 新しいChannelPanelインスタンスを作成
---@param channelManager ChannelManager チャンネルマネージャー
---@return ChannelPanel
function ChannelPanel.new(channelManager)
    local self = setmetatable({}, ChannelPanel)
    
    self.channelManager = channelManager
    self.components = Components.new()
    self.selectedChannel = 1
    self.dropdownOpen = {false, false, false, false}
    
    return self
end

---@brief チャンネルパネルを描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param height number 高さ
function ChannelPanel:draw(x, y, width, height)
    -- 背景
    love.graphics.setColor(0.12, 0.12, 0.14, 1.0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- ヘッダー
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print("チャンネル設定", x + 8, y + 8)
    
    -- チャンネル選択タブ
    local tabY = y + 32
    local tabWidth = 60
    for i = 1, 4 do
        local tabX = x + 8 + (i - 1) * (tabWidth + 4)
        local isSelected = self.selectedChannel == i
        
        if isSelected then
            love.graphics.setColor(0.33, 0.60, 0.99, 1.0)
        else
            love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
        end
        
        love.graphics.rectangle("fill", tabX, tabY, tabWidth, 28)
        
        love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
        love.graphics.printf(string.format("Ch %d", i - 1), tabX, tabY + 7, tabWidth, "center")
    end
    
    -- 選択中のチャンネル設定
    local channelY = tabY + 40
    local channel = self.channelManager:getChannel(self.selectedChannel)
    
    if channel then
        -- タイプ選択
        love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
        love.graphics.print("入力タイプ:", x + 8, channelY)
        
        local typeOptions = {
            {value = "none", label = "なし"},
            {value = "image", label = "画像"},
            {value = "noise", label = "ノイズ"},
            {value = "gradient", label = "グラデーション"},
            {value = "checker", label = "チェッカー"},
            {value = "circle", label = "円形"},
            {value = "uvgrid", label = "UVグリッド"}
        }
        
        self:drawDropdown(x + 8, channelY + 20, 180, channel.type, typeOptions, 1)
        
        -- ラップモード設定
        if channel.texture then
            love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
            love.graphics.print("ラップモード:", x + 8, channelY + 60)
            
            local wrapOptions = {
                {value = "repeat", label = "リピート"},
                {value = "clamp", label = "クランプ"},
                {value = "mirror", label = "ミラー"}
            }
            
            self:drawDropdown(x + 8, channelY + 80, 180, channel.wrapMode, wrapOptions, 2)
            
            -- フィルター設定
            love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
            love.graphics.print("フィルター:", x + 200, channelY + 60)
            
            local filterOptions = {
                {value = "linear", label = "リニア"},
                {value = "nearest", label = "ニアレスト"}
            }
            
            self:drawDropdown(x + 200, channelY + 80, 180, channel.filter, filterOptions, 3)
        end
        
        -- ファイルパス表示（画像の場合）
        if channel.type == "image" and channel.path then
            love.graphics.setColor(0.60, 0.60, 0.64, 1.0)
            local filename = channel.path:match("([^/]+)$") or channel.path
            love.graphics.print("ファイル: " .. filename, x + 8, channelY + 120)
        end
    end
end

---@brief ドロップダウンメニューを描画
---@param x number X座標
---@param y number Y座標
---@param width number 幅
---@param currentValue string 現在の値
---@param options table オプション配列
---@param dropdownIndex number ドロップダウンのインデックス
function ChannelPanel:drawDropdown(x, y, width, currentValue, options, dropdownIndex)
    local height = 28
    
    -- 現在の値を表示
    love.graphics.setColor(0.16, 0.16, 0.18, 1.0)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
    love.graphics.rectangle("line", x, y, width, height)
    
    -- 現在の値のラベルを取得
    local currentLabel = currentValue
    for _, option in ipairs(options) do
        if option.value == currentValue then
            currentLabel = option.label
            break
        end
    end
    
    love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
    love.graphics.print(currentLabel, x + 8, y + 7)
    
    -- ドロップダウン矢印
    love.graphics.print(self.dropdownOpen[dropdownIndex] and "▲" or "▼", x + width - 20, y + 7)
    
    -- ドロップダウンメニュー
    if self.dropdownOpen[dropdownIndex] then
        local menuY = y + height + 2
        
        for i, option in ipairs(options) do
            local optionY = menuY + (i - 1) * height
            
            love.graphics.setColor(0.09, 0.09, 0.11, 1.0)
            love.graphics.rectangle("fill", x, optionY, width, height)
            
            love.graphics.setColor(0.20, 0.20, 0.23, 1.0)
            love.graphics.rectangle("line", x, optionY, width, height)
            
            if option.value == currentValue then
                love.graphics.setColor(0.33, 0.60, 0.99, 1.0)
            else
                love.graphics.setColor(0.95, 0.95, 0.96, 1.0)
            end
            
            love.graphics.print(option.label, x + 8, optionY + 7)
        end
    end
end

---@brief マウスクリック処理
---@param mx number マウスX座標
---@param my number マウスY座標
---@param panelX number パネルX座標
---@param panelY number パネルY座標
---@param panelWidth number パネル幅
function ChannelPanel:mousepressed(mx, my, panelX, panelY, panelWidth)
    -- タブのクリック判定
    local tabY = panelY + 32
    local tabWidth = 60
    
    for i = 1, 4 do
        local tabX = panelX + 8 + (i - 1) * (tabWidth + 4)
        if mx >= tabX and mx <= tabX + tabWidth and my >= tabY and my <= tabY + 28 then
            self.selectedChannel = i
            -- すべてのドロップダウンを閉じる
            for j = 1, #self.dropdownOpen do
                self.dropdownOpen[j] = false
            end
            return
        end
    end
    
    -- ドロップダウンのクリック判定
    local channelY = tabY + 40
    local dropdownHeight = 28
    
    -- タイプドロップダウン
    self:handleDropdownClick(mx, my, panelX + 8, channelY + 20, 180, 1, function(value)
        if value == "none" then
            self.channelManager:clearChannel(self.selectedChannel)
        elseif value == "image" then
            -- ファイル選択ダイアログを開く（簡易版）
            print("画像ファイル選択機能は後で実装")
        else
            -- デフォルトテクスチャを設定
            self.channelManager:setDefaultTexture(self.selectedChannel, value)
        end
    end)
    
    -- ラップモードドロップダウン
    local channel = self.channelManager:getChannel(self.selectedChannel)
    if channel and channel.texture then
        self:handleDropdownClick(mx, my, panelX + 8, channelY + 80, 180, 2, function(value)
            self.channelManager:setWrapMode(self.selectedChannel, value)
        end)
        
        -- フィルターモードドロップダウン
        self:handleDropdownClick(mx, my, panelX + 200, channelY + 80, 180, 3, function(value)
            self.channelManager:setFilter(self.selectedChannel, value)
        end)
    end
end

---@brief ドロップダウンクリック処理
---@param mx number マウスX座標
---@param my number マウスY座標
---@param x number ドロップダウンX座標
---@param y number ドロップダウンY座標
---@param width number ドロップダウン幅
---@param dropdownIndex number ドロップダウンインデックス
---@param callback function 値選択時のコールバック
function ChannelPanel:handleDropdownClick(mx, my, x, y, width, dropdownIndex, callback)
    local height = 28
    
    -- ドロップダウンヘッダーのクリック
    if mx >= x and mx <= x + width and my >= y and my <= y + height then
        self.dropdownOpen[dropdownIndex] = not self.dropdownOpen[dropdownIndex]
        -- 他のドロップダウンを閉じる
        for i = 1, #self.dropdownOpen do
            if i ~= dropdownIndex then
                self.dropdownOpen[i] = false
            end
        end
        return
    end
    
    -- オプションのクリック（ドロップダウンが開いている場合）
    if self.dropdownOpen[dropdownIndex] then
        local menuY = y + height + 2
        local options = self:getOptionsForDropdown(dropdownIndex)
        
        for i, option in ipairs(options) do
            local optionY = menuY + (i - 1) * height
            if mx >= x and mx <= x + width and my >= optionY and my <= optionY + height then
                callback(option.value)
                self.dropdownOpen[dropdownIndex] = false
                return
            end
        end
    end
end

---@brief ドロップダウンのオプションを取得
---@param dropdownIndex number ドロップダウンインデックス
---@return table オプション配列
function ChannelPanel:getOptionsForDropdown(dropdownIndex)
    if dropdownIndex == 1 then
        return {
            {value = "none", label = "なし"},
            {value = "image", label = "画像"},
            {value = "noise", label = "ノイズ"},
            {value = "gradient", label = "グラデーション"},
            {value = "checker", label = "チェッカー"},
            {value = "circle", label = "円形"},
            {value = "uvgrid", label = "UVグリッド"}
        }
    elseif dropdownIndex == 2 then
        return {
            {value = "repeat", label = "リピート"},
            {value = "clamp", label = "クランプ"},
            {value = "mirror", label = "ミラー"}
        }
    elseif dropdownIndex == 3 then
        return {
            {value = "linear", label = "リニア"},
            {value = "nearest", label = "ニアレスト"}
        }
    end
    return {}
end

return ChannelPanel