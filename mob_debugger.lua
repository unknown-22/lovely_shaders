#!/usr/bin/env lua

--[[
MobDebug Debugger

mobdebug.luaのソースコードに基づいて正しいコマンドを使用
利用可能コマンド: STEP, OVER, OUT, RUN, STACK, SETB, DELB, SETW, DELW, EXEC, LOAD, SUSPEND, OUTPUT, BASEDIR

使用方法:
1. lua mob_debugger.lua
2. love . -debug
--]]

local socket = require("socket")

print("=== MobDebug Debugger ===")
print("MobDebugプロトコルに基づくデバッガー")
print("Love2Dアプリケーションからの接続を待機中...")
print("")

-- サーバーソケット作成
local server = socket.bind("*", 8172)
if not server then
    print("エラー: ポート 8172 でサーバーを開始できませんでした")
    return
end

print("ポート 8172 で待機中...")

-- クライアント接続待機
local client = server:accept()
print("\nLove2Dアプリケーションが接続されました！")

-- ブレークポイントとウォッチ式を記録
local breakpoints = {}
local watches = {}
local watch_counter = 1

-- 初期化
client:send("STEP\n")
local response = client:receive("*l")
print("初期レスポンス:", response or "なし")

-- 一時停止位置情報を取得
local pause_info = client:receive("*l")
if pause_info then
    print("一時停止情報:", pause_info)
end

-- コマンド送信とレスポンス処理の共通関数
local function send_command(cmd_string)
    print("送信: " .. cmd_string:gsub("\n", ""))
    client:send(cmd_string)
    
    local response = client:receive("*l")
    if response then
        print("レスポンス:", response)
        
        -- 200 OK with data
        if string.find(response, "^200 OK (%d+)") then
            local size = response:match("^200 OK (%d+)")
            if size then
                local data = client:receive(tonumber(size))
                if data and data ~= "" then
                    print("結果:")
                    print(data)
                end
            end
        -- 202 Paused
        elseif string.find(response, "^202 Paused") then
            local extra = client:receive("*l")
            if extra then
                print("停止位置:", extra)
            end
        -- エラー
        elseif string.find(response, "^40") then
            print("エラー:", response)
        end
        
        return response
    else
        print("レスポンスなし")
        return nil
    end
end

-- コマンド処理関数
local function handle_command(command)
    if not command or command == "" then
        return true
    end
    
    local parts = {}
    for part in command:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    local cmd = parts[1]:lower()
    
    -- ヘルプ
    if cmd == "help" or cmd == "h" then
        print([[
利用可能なコマンド（MobDebugプロトコル）:
  step, s             - 次の行まで実行（ステップイン）
  over, n             - 次の行まで実行（ステップオーバー）
  out, o              - 関数から戻るまで実行
  run, c              - 次のブレークポイントまで実行
  
  setb <file> <line>  - ブレークポイント設定
  delb <file> <line>  - ブレークポイント削除
  listb               - ブレークポイント一覧（ローカル記録）
  
  setw <expr>         - ウォッチ式設定
  delw <index>        - ウォッチ式削除
  listw               - ウォッチ式一覧
  
  exec <stmt>         - Lua文を実行
  stack [opts]        - スタックトレース表示
  
  suspend             - 実行を一時停止
  output <stream> <mode> - 出力設定
  basedir <path>      - ベースディレクトリ設定
  
  done                - デバッガー停止、アプリ継続
  exit, quit          - 終了
  help, h             - このヘルプ

例:
  setb main.lua 25    - ブレークポイント設定
  exec print(player.x) - 式を実行
  setw player.x       - プレイヤーのx座標を監視
  stack               - スタック表示
]])
        return true
    end
    
    -- 終了コマンド
    if cmd == "exit" or cmd == "quit" then
        send_command("EXIT\n")
        return false
    end
    
    if cmd == "done" then
        send_command("DONE\n")
        return false
    end
    
    -- 省略形マッピング
    local cmd_map = {
        s = "step",
        n = "over", 
        o = "out",
        c = "run"
    }
    
    local full_cmd = cmd_map[cmd] or cmd
    
    -- 実行制御コマンド
    if full_cmd == "step" then
        send_command("STEP\n")
    elseif full_cmd == "over" then
        send_command("OVER\n")
    elseif full_cmd == "out" then
        send_command("OUT\n")
    elseif full_cmd == "run" then
        send_command("RUN\n")
    
    -- スタック情報
    elseif full_cmd == "stack" then
        local opts = parts[2] or ""
        if opts ~= "" then
            send_command("STACK " .. opts .. "\n")
        else
            send_command("STACK\n")
        end
    
    -- ブレークポイント管理
    elseif full_cmd == "setb" then
        if #parts >= 3 then
            local file, line = parts[2], parts[3]
            local response = send_command(string.format("SETB %s %s\n", file, line))
            
            -- 成功した場合、ローカルで記録
            if response and string.find(response, "^200") then
                local key = file .. ":" .. line
                breakpoints[key] = {file = file, line = tonumber(line)}
                print(string.format("ブレークポイントを記録: %s:%s", file, line))
            end
        else
            print("使用方法: setb <file> <line>")
            print("例: setb main.lua 25")
        end
    
    elseif full_cmd == "delb" then
        if #parts >= 3 then
            local file, line = parts[2], parts[3]
            local response = send_command(string.format("DELB %s %s\n", file, line))
            
            -- 成功した場合、ローカル記録から削除
            if response and string.find(response, "^200") then
                local key = file .. ":" .. line
                breakpoints[key] = nil
                print(string.format("ブレークポイントを削除: %s:%s", file, line))
            end
        else
            print("使用方法: delb <file> <line>")
            print("例: delb main.lua 25")
        end
    
    elseif full_cmd == "listb" then
        print("設定済みブレークポイント:")
        local count = 0
        for key, bp in pairs(breakpoints) do
            print(string.format("  %s:%d", bp.file, bp.line))
            count = count + 1
        end
        if count == 0 then
            print("  （ブレークポイントなし）")
        end
        print(string.format("合計: %d個", count))
    
    -- ウォッチ式管理
    elseif full_cmd == "setw" then
        if #parts >= 2 then
            local expr = table.concat(parts, " ", 2)
            local response = send_command(string.format("SETW %s\n", expr))
            
            -- 成功した場合、ローカルで記録
            if response and string.find(response, "^200") then
                watches[watch_counter] = expr
                print(string.format("ウォッチ式を設定: [%d] %s", watch_counter, expr))
                watch_counter = watch_counter + 1
            end
        else
            print("使用方法: setw <expression>")
            print("例: setw player.x")
            print("例: setw love.timer.getTime()")
        end
    
    elseif full_cmd == "delw" then
        if #parts >= 2 then
            local index = tonumber(parts[2])
            if index and watches[index] then
                local response = send_command(string.format("DELW %d\n", index))
                
                if response and string.find(response, "^200") then
                    print(string.format("ウォッチ式を削除: [%d] %s", index, watches[index]))
                    watches[index] = nil
                end
            else
                print("無効なウォッチ式インデックス:", parts[2])
            end
        else
            print("使用方法: delw <index>")
            print("例: delw 1")
        end
    
    elseif full_cmd == "listw" then
        print("設定済みウォッチ式:")
        local count = 0
        for index, expr in pairs(watches) do
            print(string.format("  [%d] %s", index, expr))
            count = count + 1
        end
        if count == 0 then
            print("  （ウォッチ式なし）")
        end
        print(string.format("合計: %d個", count))
    
    -- コード実行
    elseif full_cmd == "exec" then
        if #parts >= 2 then
            local stmt = table.concat(parts, " ", 2)
            send_command(string.format("EXEC %s\n", stmt))
        else
            print("使用方法: exec <statement>")
            print("例: exec print(player.x)")
            print("例: exec player.x = 100")
            print("例: exec local t = love.timer.getTime(); print('Time:', t)")
        end
    
    -- システムコマンド
    elseif full_cmd == "suspend" then
        send_command("SUSPEND\n")
    
    elseif full_cmd == "output" then
        if #parts >= 3 then
            local stream, mode = parts[2], parts[3]
            send_command(string.format("OUTPUT %s %s\n", stream, mode))
        else
            print("使用方法: output <stream> <mode>")
            print("例: output stdout copy")
        end
    
    elseif full_cmd == "basedir" then
        if #parts >= 2 then
            local path = parts[2]
            send_command(string.format("BASEDIR %s\n", path))
        else
            print("使用方法: basedir <path>")
            print("例: basedir /path/to/project")
        end
    
    else
        print("不明なコマンド:", cmd)
        print("'help' でコマンド一覧を表示")
    end
    
    return true
end

-- メインループ
print("\nデバッグセッション開始")
print("'help' でコマンド一覧を表示")
print("")

local continue = true
while continue do
    io.write("> ")
    io.flush()
    
    local command = io.read("*line")
    if not command then
        break
    end
    
    continue = handle_command(command)
end

-- クリーンアップ
print("\nセッション終了...")
client:close()
server:close()
print("デバッグセッション完了")