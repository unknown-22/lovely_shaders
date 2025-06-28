#!/bin/bash

#
# MobDebug Quick Test Script
# デバッグ環境の簡単な動作確認用
#

echo "=== MobDebug 環境テスト ==="

# 1. 必要なコマンドの確認
echo "1. 必要なコマンドの確認中..."

if ! command -v lua >/dev/null 2>&1; then
    echo "❌ lua コマンドが見つかりません"
    exit 1
else
    echo "✓ lua: $(lua -v 2>&1 | head -n1)"
fi

if ! command -v love >/dev/null 2>&1; then
    echo "❌ love コマンドが見つかりません"
    exit 1
else
    echo "✓ love: $(love --version 2>&1 | head -n1)"
fi

if ! command -v lsof >/dev/null 2>&1; then
    echo "❌ lsof コマンドが見つかりません"
    exit 1
else
    echo "✓ lsof: 利用可能"
fi

# 2. 必要なファイルの確認
echo ""
echo "2. 必要なファイルの確認中..."

if [ ! -f "mob_debugger.lua" ]; then
    echo "❌ mob_debugger.lua が見つかりません"
    exit 1
else
    echo "✓ mob_debugger.lua: 存在"
fi

if [ ! -f "mobdebug.lua" ]; then
    echo "❌ mobdebug.lua が見つかりません"
    exit 1
else
    echo "✓ mobdebug.lua: 存在"
fi

if [ ! -f "main.lua" ]; then
    echo "❌ main.lua が見つかりません"
    exit 1
else
    echo "✓ main.lua: 存在"
fi

# 3. ポート8172の使用状況確認
echo ""
echo "3. ポート8172の使用状況確認..."

if lsof -i :8172 >/dev/null 2>&1; then
    echo "❌ ポート8172は既に使用されています:"
    lsof -i :8172
    echo "プロセスを終了してから再試行してください"
    exit 1
else
    echo "✓ ポート8172: 利用可能"
fi

# 4. Luaスクリプトの文法チェック
echo ""
echo "4. Luaスクリプトの文法チェック..."

if lua -e "dofile('mobdebug.lua')" 2>/dev/null; then
    echo "✓ mobdebug.lua: 文法OK"
else
    echo "❌ mobdebug.lua: 文法エラーがあります"
    lua -e "dofile('mobdebug.lua')"
    exit 1
fi

if lua -e "loadfile('mob_debugger.lua')" 2>/dev/null; then
    echo "✓ mob_debugger.lua: 文法OK"
else
    echo "❌ mob_debugger.lua: 文法エラーがあります"
    lua -e "loadfile('mob_debugger.lua')"
    exit 1
fi

# 5. Love2Dプロジェクトの基本チェック
echo ""
echo "5. Love2Dプロジェクトの基本チェック..."

if [ -f "conf.lua" ]; then
    echo "✓ conf.lua: 存在"
else
    echo "⚠ conf.lua: 存在しない（オプション）"
fi

# main.luaでMobDebugコードが有効かチェック
if grep -q "mobdebug" main.lua; then
    echo "✓ main.lua: MobDebugコードが見つかりました"
else
    echo "❌ main.lua: MobDebugコードが見つかりません"
    echo "main.luaにMobDebugの初期化コードが必要です"
    exit 1
fi

# 6. シェルスクリプトの確認
echo ""
echo "6. シェルスクリプトの確認..."

if [ -f "auto_debug_session.sh" ]; then
    if [ -x "auto_debug_session.sh" ]; then
        echo "✓ auto_debug_session.sh: 実行可能"
    else
        echo "⚠ auto_debug_session.sh: 実行権限がありません"
        echo "chmod +x auto_debug_session.sh を実行してください"
    fi
else
    echo "❌ auto_debug_session.sh が見つかりません"
    exit 1
fi

# 7. 依存関係の確認
echo ""
echo "7. Lua依存関係の確認..."

# socket library
if lua -e "require('socket')" 2>/dev/null; then
    echo "✓ luasocket: 利用可能"
else
    echo "❌ luasocket: 見つかりません"
    echo "sudo apt install lua-socket または luarocks install luasocket が必要です"
    exit 1
fi

# 8. デバッグコマンドファイルの確認
echo ""
echo "8. デバッグコマンドファイルの確認..."

if [ -f "debug_commands_default.txt" ]; then
    echo "✓ debug_commands_default.txt: 存在"
else
    echo "❌ debug_commands_default.txt が見つかりません"
    exit 1
fi

if [ -f "debug_commands_custom.txt" ]; then
    echo "✓ debug_commands_custom.txt: 存在"
else
    echo "⚠ debug_commands_custom.txt: 存在しない（オプション）"
fi

echo ""
echo "🎉 すべてのテストが完了しました！"
echo ""
echo "=== 使用方法 ==="
echo "1. 自動デバッグセッション（デフォルト）:"
echo "   ./auto_debug_session.sh"
echo ""
echo "2. 自動デバッグセッション（カスタム）:"
echo "   ./auto_debug_session.sh debug_commands_custom.txt"
echo ""
echo "3. 手動でデバッグする場合:"
echo "   ./interactive_debug.sh"
echo ""
echo "4. ヘルプ表示:"
echo "   ./auto_debug_session.sh --help"
echo ""
echo "詳細は DEBUG_COMMANDS_README.md を参照してください"
echo ""
