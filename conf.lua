---@file conf.lua
---@brief Love2D設定ファイル
---@details Lovely Shadersアプリケーションの基本設定を定義

---@brief Love2D設定関数
---@param t table Love2D設定テーブル
function love.conf(t)
    t.title = "Lovely Shaders"
    t.author = "Lovely Shaders Team"
    t.identity = "lovely_shaders"
    t.version = "11.5"
    t.console = true
    t.accelerometerjoystick = false
    t.externalstorage = false
    t.gammacorrect = false

    t.audio.mic = false
    t.audio.mixwithsystem = true

    t.window.title = "Lovely Shaders"
    t.window.icon = nil
    t.window.width = 1280
    t.window.height = 720
    t.window.borderless = false
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.window.msaa = 0
    t.window.depth = nil
    t.window.stencil = nil
    t.window.display = 1
    t.window.highdpi = false
    t.window.usedpiscale = true
    t.window.x = nil
    t.window.y = nil

    t.modules.audio = true
    t.modules.data = true
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = true
end