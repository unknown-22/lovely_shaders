---@file core/uniform_manager.lua
---@brief カスタムUniform変数管理
---@details GUI経由でのfloat/vec2/vec3/vec4パラメータ追加・管理機能

---@class UniformParam
---@field name string Uniform変数名
---@field type string 型名（float, vec2, vec3, vec4）
---@field value number|table 現在値
---@field min number 最小値
---@field max number 最大値
---@field default number|table デフォルト値

---@class UniformManager
---@field uniforms table<string, UniformParam> カスタムUniform変数
local UniformManager = {}
UniformManager.__index = UniformManager

---@brief UniformManagerコンストラクタ
---@return UniformManager
function UniformManager.new()
    local self = setmetatable({}, UniformManager)
    self.uniforms = {}
    return self
end

---@brief Float型Uniform変数を追加
---@param name string 変数名
---@param defaultValue number デフォルト値
---@param minValue number 最小値
---@param maxValue number 最大値
function UniformManager:addFloat(name, defaultValue, minValue, maxValue)
    if not name or name == "" then
        error("Uniform variable name cannot be empty")
    end
    
    self.uniforms[name] = {
        name = name,
        type = "float",
        value = defaultValue or 0.0,
        min = minValue or 0.0,
        max = maxValue or 1.0,
        default = defaultValue or 0.0
    }
end

---@brief Vec2型Uniform変数を追加
---@param name string 変数名
---@param defaultValue table デフォルト値 {x, y}
---@param minValue number 最小値
---@param maxValue number 最大値
function UniformManager:addVec2(name, defaultValue, minValue, maxValue)
    if not name or name == "" then
        error("Uniform variable name cannot be empty")
    end
    
    local default = defaultValue or {0.0, 0.0}
    self.uniforms[name] = {
        name = name,
        type = "vec2",
        value = {default[1], default[2]},
        min = minValue or 0.0,
        max = maxValue or 1.0,
        default = {default[1], default[2]}
    }
end

---@brief Vec3型Uniform変数を追加
---@param name string 変数名
---@param defaultValue table デフォルト値 {x, y, z}
---@param minValue number 最小値
---@param maxValue number 最大値
function UniformManager:addVec3(name, defaultValue, minValue, maxValue)
    if not name or name == "" then
        error("Uniform variable name cannot be empty")
    end
    
    local default = defaultValue or {0.0, 0.0, 0.0}
    self.uniforms[name] = {
        name = name,
        type = "vec3",
        value = {default[1], default[2], default[3]},
        min = minValue or 0.0,
        max = maxValue or 1.0,
        default = {default[1], default[2], default[3]}
    }
end

---@brief Vec4型Uniform変数を追加
---@param name string 変数名
---@param defaultValue table デフォルト値 {x, y, z, w}
---@param minValue number 最小値
---@param maxValue number 最大値
function UniformManager:addVec4(name, defaultValue, minValue, maxValue)
    if not name or name == "" then
        error("Uniform variable name cannot be empty")
    end
    
    local default = defaultValue or {0.0, 0.0, 0.0, 1.0}
    self.uniforms[name] = {
        name = name,
        type = "vec4",
        value = {default[1], default[2], default[3], default[4]},
        min = minValue or 0.0,
        max = maxValue or 1.0,
        default = {default[1], default[2], default[3], default[4]}
    }
end

---@brief Uniform変数を削除
---@param name string 変数名
function UniformManager:removeUniform(name)
    self.uniforms[name] = nil
end

---@brief 全てのUniform変数をクリア
function UniformManager:clearAll()
    self.uniforms = {}
end

---@brief Uniform変数の値を設定
---@param name string 変数名
---@param value number|table 設定値
function UniformManager:setValue(name, value)
    local uniform = self.uniforms[name]
    if not uniform then
        return false
    end
    
    if uniform.type == "float" then
        if type(value) == "number" then
            uniform.value = math.max(uniform.min, math.min(uniform.max, value))
            return true
        end
    elseif uniform.type == "vec2" then
        if type(value) == "table" and #value >= 2 then
            uniform.value[1] = math.max(uniform.min, math.min(uniform.max, value[1]))
            uniform.value[2] = math.max(uniform.min, math.min(uniform.max, value[2]))
            return true
        end
    elseif uniform.type == "vec3" then
        if type(value) == "table" and #value >= 3 then
            uniform.value[1] = math.max(uniform.min, math.min(uniform.max, value[1]))
            uniform.value[2] = math.max(uniform.min, math.min(uniform.max, value[2]))
            uniform.value[3] = math.max(uniform.min, math.min(uniform.max, value[3]))
            return true
        end
    elseif uniform.type == "vec4" then
        if type(value) == "table" and #value >= 4 then
            uniform.value[1] = math.max(uniform.min, math.min(uniform.max, value[1]))
            uniform.value[2] = math.max(uniform.min, math.min(uniform.max, value[2]))
            uniform.value[3] = math.max(uniform.min, math.min(uniform.max, value[3]))
            uniform.value[4] = math.max(uniform.min, math.min(uniform.max, value[4]))
            return true
        end
    end
    
    return false
end

---@brief Uniform変数の値を取得
---@param name string 変数名
---@return number|table|nil 値
function UniformManager:getValue(name)
    local uniform = self.uniforms[name]
    if not uniform then
        return nil
    end
    
    if uniform.type == "float" then
        return uniform.value
    else
        -- テーブルのコピーを返す
        local copy = {}
        for i, v in ipairs(uniform.value) do
            copy[i] = v
        end
        return copy
    end
end

---@brief 全てのUniform変数を取得
---@return table<string, UniformParam>
function UniformManager:getAllUniforms()
    return self.uniforms
end

---@brief Uniform変数が存在するかチェック
---@param name string 変数名
---@return boolean
function UniformManager:exists(name)
    return self.uniforms[name] ~= nil
end

---@brief Uniform変数をデフォルト値にリセット
---@param name string 変数名
function UniformManager:resetToDefault(name)
    local uniform = self.uniforms[name]
    if not uniform then
        return false
    end
    
    if uniform.type == "float" then
        uniform.value = uniform.default
    else
        for i, v in ipairs(uniform.default) do
            uniform.value[i] = v
        end
    end
    
    return true
end

---@brief 全てのUniform変数をデフォルト値にリセット
function UniformManager:resetAllToDefault()
    for name, _ in pairs(self.uniforms) do
        self:resetToDefault(name)
    end
end

---@brief シェーダーにUniform変数を適用
---@param shader love.Shader Love2Dシェーダーオブジェクト
function UniformManager:applyToShader(shader)
    if not shader then
        return
    end
    
    for name, uniform in pairs(self.uniforms) do
        local success, err = pcall(function()
            shader:send(name, uniform.value)
        end)
        
        if not success then
            print("Warning: Failed to send uniform '" .. name .. "': " .. tostring(err))
        end
    end
end

---@brief 設定をJSONに変換
---@return table
function UniformManager:toTable()
    local result = {}
    for name, uniform in pairs(self.uniforms) do
        result[name] = {
            type = uniform.type,
            value = uniform.value,
            min = uniform.min,
            max = uniform.max,
            default = uniform.default
        }
    end
    return result
end

---@brief JSONから設定を復元
---@param data table 設定データ
function UniformManager:fromTable(data)
    if type(data) ~= "table" then
        return false
    end
    
    self.uniforms = {}
    
    for name, uniformData in pairs(data) do
        if type(uniformData) == "table" and uniformData.type then
            self.uniforms[name] = {
                name = name,
                type = uniformData.type,
                value = uniformData.value,
                min = uniformData.min or 0.0,
                max = uniformData.max or 1.0,
                default = uniformData.default
            }
        end
    end
    
    return true
end

return UniformManager