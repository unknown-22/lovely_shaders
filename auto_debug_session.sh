#!/bin/bash

#
# Automated MobDebug Session Script
# 自動化されたデバッグセッション（手動入力不要）
#

# 設定
DEBUG_PORT=8172
DEBUGGER_LOG="debugger.log"
LOVE_LOG="love.log"
SESSION_DIR="debug_session"
DEFAULT_COMMANDS_FILE="debug_commands_default.txt"

# 色付きログ関数
log_info() {
    echo -e "\033[32m[INFO]\033[0m $1" >&2
}

log_warn() {
    echo -e "\033[33m[WARN]\033[0m $1" >&2
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
}

# クリーンアップ関数
cleanup() {
    log_info "デバッグセッションをクリーンアップ中..."
    
    if [ ! -z "$DEBUGGER_PID" ]; then
        kill $DEBUGGER_PID 2>/dev/null
        log_info "デバッガープロセス ($DEBUGGER_PID) を終了"
    fi
    
    if [ ! -z "$LOVE_PID" ]; then
        kill $LOVE_PID 2>/dev/null
        log_info "Love2Dプロセス ($LOVE_PID) を終了"
    fi
    
    if [ ! -z "$MONITOR_PID" ]; then
        kill $MONITOR_PID 2>/dev/null
    fi
    
    pkill -f "lua.*mob_debugger.lua" 2>/dev/null
    
    log_info "クリーンアップ完了"
    exit 0
}

trap cleanup SIGINT SIGTERM

# ヘルプ表示
show_help() {
    echo "使用方法: $0 [デバッグコマンドファイル]" >&2
    echo "" >&2
    echo "オプション:" >&2
    echo "  デバッグコマンドファイル  実行するMobDebugコマンドが記載されたファイル" >&2
    echo "                          未指定の場合は debug_commands_default.txt を使用" >&2
    echo "" >&2
    echo "例:" >&2
    echo "  $0                              # デフォルトコマンドで実行" >&2
    echo "  $0 debug_commands_custom.txt    # カスタムコマンドで実行" >&2
    echo "  $0 my_debug_scenario.txt        # 独自シナリオで実行" >&2
    echo "" >&2
    echo "利用可能なコマンドファイル:" >&2
    ls -1 debug_commands_*.txt 2>/dev/null | sed 's/^/  /' >&2 || echo "  なし" >&2
    echo "" >&2
}

# ヘルプオプションのチェック
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# セッションディレクトリ作成
mkdir -p "$SESSION_DIR"
cd "$SESSION_DIR"

log_info "=== 自動化MobDebugセッション ==="

# 既存のプロセスをチェック
if lsof -i :$DEBUG_PORT >/dev/null 2>&1; then
    log_error "ポート $DEBUG_PORT は既に使用されています"
    exit 1
fi

# コマンドライン引数の処理
COMMANDS_FILE="$DEFAULT_COMMANDS_FILE"
if [ ! -z "$1" ]; then
    COMMANDS_FILE="$1"
fi

log_info "=== ステップ1: デバッガーサーバー起動 ==="

# デバッグコマンドファイルの確認と準備
prepare_debug_commands() {
    local source_file="../$COMMANDS_FILE"
    
    # 指定されたコマンドファイルが存在するかチェック
    if [ ! -f "$source_file" ]; then
        log_error "デバッグコマンドファイルが見つかりません: $COMMANDS_FILE"
        log_info "現在のディレクトリ: $(pwd)"
        log_info "探索パス: $source_file"
        log_info ""
        log_info "利用可能なファイル:"
        ls -la ../debug_commands_*.txt 2>/dev/null | sed 's/^/  /' >&2 || log_info "  デフォルトファイルがありません" >&2
        exit 1
    fi
    
    # セッションディレクトリにコピー
    cp "$source_file" "debug_commands.txt"
    log_info "デバッグコマンドファイルを準備しました: $COMMANDS_FILE"
    
    # コマンド内容を表示
    log_info "実行予定のデバッグコマンド:"
    echo "================================" >&2
    grep -v '^#' "debug_commands.txt" | grep -v '^[[:space:]]*$' | sed 's/^/  /' >&2
    echo "================================" >&2
}

# デバッグコマンドファイル準備
prepare_debug_commands

# 自動化されたデバッガーを起動
log_info "自動化デバッガーを起動中..."

(
    cd ..
    
    # デバッガーにコマンドを自動送信（stdoutのみを使用）
    (
        sleep 3  # サーバー起動を待機
        
        while IFS= read -r command; do
            if [ ! -z "$command" ] && [[ ! "$command" =~ ^# ]]; then
                echo "$command"
                sleep 1
            fi
        done < "$SESSION_DIR/debug_commands.txt"
        
        # 3秒間実行を継続
        sleep 3
        
        # 終了コマンド
        echo "quit"
        
    ) | lua mob_debugger.lua > "$SESSION_DIR/$DEBUGGER_LOG" 2>&1
    
) &
DEBUGGER_PID=$!

# デバッガーサーバーの起動待機
log_info "デバッガーサーバーの起動を待機中..."
for i in {1..10}; do
    if lsof -i :$DEBUG_PORT >/dev/null 2>&1; then
        log_info "デバッガーサーバーが起動しました (試行 $i/10)"
        break
    fi
    sleep 1
    if [ $i -eq 10 ]; then
        log_error "デバッガーサーバーの起動に失敗"
        cat "$DEBUGGER_LOG" 2>/dev/null
        exit 1
    fi
done

log_info "=== ステップ2: Love2Dアプリケーション起動 ==="
sleep 2

# Love2Dアプリケーションを起動
cd ..
love . --debug > "$SESSION_DIR/$LOVE_LOG" 2>&1 &
LOVE_PID=$!
cd "$SESSION_DIR"

log_info "Love2D PID: $LOVE_PID"

# 接続待機
log_info "デバッガー接続と自動実行を待機中..."
sleep 1

# Love2Dプロセスの確認
if ! kill -0 $LOVE_PID 2>/dev/null; then
    log_error "Love2Dアプリケーションの起動に失敗"
    cat "$LOVE_LOG"
    cleanup
    exit 1
fi

log_info "=== デバッグセッション実行中 ==="

# ログモニタリング関数
monitor_and_display() {
    local start_time=$(date +%s)
    local max_duration=30  # 30秒間実行
    local last_debugger_size=0
    local last_love_size=0
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -gt $max_duration ]; then
            log_info "最大実行時間（${max_duration}秒）に達しました"
            break
        fi
        
        # デバッガーログの新しい内容を表示
        if [ -f "$DEBUGGER_LOG" ]; then
            local current_size=$(wc -c < "$DEBUGGER_LOG" 2>/dev/null || echo 0)
            if [ $current_size -gt $last_debugger_size ]; then
                echo ""
                echo "=== デバッガーログ (新着) ===" >&2
                tail -c +$((last_debugger_size + 1)) "$DEBUGGER_LOG" | sed 's/^/[DEBUGGER] /' >&2
                echo "================================" >&2
                last_debugger_size=$current_size
            fi
        fi
        
        # Love2Dログも表示
        if [ -f "$LOVE_LOG" ]; then
            local current_size=$(wc -c < "$LOVE_LOG" 2>/dev/null || echo 0)
            if [ $current_size -gt $last_love_size ]; then
                echo ""
                echo "=== Love2Dログ (新着) ===" >&2
                tail -c +$((last_love_size + 1)) "$LOVE_LOG" | sed 's/^/[LOVE2D] /' >&2
                echo "============================" >&2
                last_love_size=$current_size
            fi
        fi
        
        # プロセス確認
        if ! kill -0 $LOVE_PID 2>/dev/null; then
            log_warn "Love2Dプロセスが終了しました"
            break
        fi
        
        if ! kill -0 $DEBUGGER_PID 2>/dev/null; then
            log_info "デバッガープロセスが正常終了しました"
            break
        fi
        
        sleep 1
    done
}

# モニタリング開始
monitor_and_display

log_info "=== セッション完了 ==="

echo "" >&2
echo "=== 最終ログ ===" >&2
echo "デバッガーログ:" >&2
echo "===============" >&2
cat "$DEBUGGER_LOG" 2>/dev/null || echo "ログなし" >&2
echo "" >&2
echo "Love2Dログ:" >&2
echo "==========" >&2
cat "$LOVE_LOG" 2>/dev/null || echo "ログなし" >&2

cleanup