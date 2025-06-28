---@file core/file_manager.lua
---@brief ファイル管理モジュール
---@details シェーダーファイルの保存・読み込み機能を提供

---@class FileManager
---@field currentFile string 現在のファイルパス
---@field lastSaveTime number 最後の保存時刻
---@field isModified boolean 変更フラグ
local FileManager = {}
FileManager.__index = FileManager

local DEFAULT_SHADER_CONTENT = [[#version 300 es
precision highp float;

uniform float iTime;
uniform vec3 iResolution;
uniform vec4 iMouse;

out vec4 fragColor;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3 col = 0.5 + 0.5 * cos(iTime + uv.xyx + vec3(0, 2, 4));
    fragColor = vec4(col, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}]]

---@brief ファイルマネージャー新規作成
---@return FileManager
function FileManager.new()
    local self = setmetatable({}, FileManager)
    
    self.currentFile = nil
    self.lastSaveTime = 0
    self.isModified = false
    
    return self
end

---@brief ファイル保存
---@param content string 保存するコンテンツ
---@param filename string|nil ファイル名（未指定時は現在のファイル）
---@return boolean 保存成功フラグ
function FileManager:save(content, filename)
    if not content then
        print("警告: 保存するコンテンツが空です")
        return false
    end
    
    local targetFile = filename or self.currentFile
    
    if not targetFile then
        local dialogResult = self:openSaveDialog()
        if not dialogResult then
            print("保存がキャンセルされました")
            return false
        end
        targetFile = dialogResult
    end
    
    local success, errorMsg = pcall(function()
        local _ = love.filesystem.write(targetFile, content)
    end)
    
    if success then
        self.currentFile = targetFile
        self.lastSaveTime = love.timer.getTime()
        self.isModified = false
        print(string.format("ファイルを保存しました: %s", targetFile))
        return true
    else
        print(string.format("保存エラー: %s", errorMsg))
        return false
    end
end

---@brief ファイル読み込み
---@param filename string|nil ファイル名（未指定時はダイアログ表示）
---@return string|nil 読み込んだコンテンツ
function FileManager:load(filename)
    local targetFile = filename
    
    if not targetFile then
        targetFile = self:openLoadDialog()
        if not targetFile then
            print("読み込みがキャンセルされました")
            return nil
        end
    end
    
    local success, content = pcall(love.filesystem.read, targetFile)
    
    if success then
        self.currentFile = targetFile
        self.isModified = false
        print(string.format("ファイルを読み込みました: %s", targetFile))
        return content
    else
        print(string.format("読み込みエラー: %s", content))
        return nil
    end
end

---@brief デフォルトシェーダー内容取得
---@return string デフォルトシェーダー内容
function FileManager:getDefaultContent()
    return DEFAULT_SHADER_CONTENT
end

---@brief 保存ダイアログ表示（簡易版）
---@return string|nil ファイルパス
function FileManager:openSaveDialog()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local defaultName = string.format("shader_%s.glsl", timestamp)
    print(string.format("ファイル名を指定してください（デフォルト: %s）", defaultName))
    return defaultName
end

---@brief 読み込みダイアログ表示（簡易版）
---@return string|nil ファイルパス
function FileManager:openLoadDialog()
    print("読み込むファイルを指定してください")
    
    local files = love.filesystem.getDirectoryItems("")
    local shaderFiles = {}
    
    for _, file in ipairs(files) do
        if file:match("%.glsl$") then
            table.insert(shaderFiles, file)
        end
    end
    
    if #shaderFiles > 0 then
        print("利用可能なシェーダーファイル:")
        for i, file in ipairs(shaderFiles) do
            print(string.format("  %d: %s", i, file))
        end
        return shaderFiles[1]
    else
        return "shaders/default.glsl"
    end
end

---@brief プロジェクト保存
---@param shaderContent string シェーダーコンテンツ
---@param settings table 設定情報
---@param projectName string|nil プロジェクト名
---@return boolean 保存成功フラグ
function FileManager:saveProject(shaderContent, settings, projectName)
    projectName = projectName or "untitled_project"
    
    local projectData = {
        version = "1.0",
        created = os.date("%Y-%m-%d %H:%M:%S"),
        modified = os.date("%Y-%m-%d %H:%M:%S"),
        shader = shaderContent,
        settings = settings or {}
    }
    
    local json = self:encodeJson(projectData)
    local filename = projectName .. ".lsp"
    
    return self:save(json, filename)
end

---@brief プロジェクト読み込み
---@param filename string|nil プロジェクトファイル名
---@return table|nil プロジェクトデータ
function FileManager:loadProject(filename)
    local content = self:load(filename)
    if not content then
        return nil
    end
    
    local projectData = self:decodeJson(content)
    if projectData then
        projectData.modified = os.date("%Y-%m-%d %H:%M:%S")
        return projectData
    else
        print("プロジェクトファイルの形式が正しくありません")
        return nil
    end
end

---@brief JSON エンコード（簡易版）
---@param data table データ
---@return string JSON文字列
function FileManager:encodeJson(data)
    local function escape(str)
        return str:gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    end
    
    local function serialize(obj, depth)
        depth = depth or 0
        if depth > 10 then return "null" end
        
        if type(obj) == "table" then
            local result = "{"
            local first = true
            for k, v in pairs(obj) do
                if not first then result = result .. "," end
                first = false
                result = result .. '"' .. escape(tostring(k)) .. '":' .. serialize(v, depth + 1)
            end
            return result .. "}"
        elseif type(obj) == "string" then
            return '"' .. escape(obj) .. '"'
        elseif type(obj) == "number" then
            return tostring(obj)
        elseif type(obj) == "boolean" then
            return obj and "true" or "false"
        else
            return "null"
        end
    end
    
    return serialize(data)
end

---@brief JSON デコード（簡易版）
---@param jsonStr string JSON文字列
---@return table|nil デコード結果
function FileManager:decodeJson(jsonStr)
    local success, result = pcall(function()
        local f = loadstring("return " .. jsonStr:gsub(":", "="):gsub(",", ",\n"))
        if f then
            return f()
        end
        return nil
    end)
    
    if success then
        return result
    else
        print("JSON解析エラー: " .. tostring(result))
        return nil
    end
end

---@brief ファイル存在確認
---@param filename string ファイル名
---@return boolean ファイル存在フラグ
function FileManager:fileExists(filename)
    local info = love.filesystem.getInfo(filename)
    return info ~= nil and info.type == "file"
end

---@brief 現在のファイルパス取得
---@return string|nil 現在のファイルパス
function FileManager:getCurrentFile()
    return self.currentFile
end

---@brief 変更状態取得
---@return boolean 変更フラグ
function FileManager:isFileModified()
    return self.isModified
end

---@brief 変更状態設定
---@param modified boolean 変更フラグ
function FileManager:setModified(modified)
    self.isModified = modified
end

---@brief 最近のファイルリスト取得
---@return table 最近のファイルリスト
function FileManager:getRecentFiles()
    local files = love.filesystem.getDirectoryItems("")
    local shaderFiles = {}
    
    for _, file in ipairs(files) do
        if file:match("%.glsl$") or file:match("%.lsp$") then
            local info = love.filesystem.getInfo(file)
            if info and info.type == "file" then
                table.insert(shaderFiles, {
                    name = file,
                    modified = info.modtime or 0
                })
            end
        end
    end
    
    table.sort(shaderFiles, function(a, b)
        return a.modified > b.modified
    end)
    
    local result = {}
    for i = 1, math.min(5, #shaderFiles) do
        table.insert(result, shaderFiles[i].name)
    end
    
    return result
end

return FileManager