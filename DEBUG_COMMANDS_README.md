# MobDebug 自動デバッグコマンドファイル

## 概要

`auto_debug_session.sh` は外部のコマンドファイルを読み込んでMobDebugの自動デバッグセッションを実行できます。

## 使用方法

### 基本的な使用

```bash
# デフォルトコマンドで実行
./auto_debug_session.sh

# カスタムコマンドファイルを指定
./auto_debug_session.sh debug_commands_custom.txt

# ヘルプ表示
./auto_debug_session.sh --help
```

## 提供されるコマンドファイル

### `debug_commands_default.txt`
- Love2Dアプリケーションの基本的なデバッグ
- `love.update`関数でのブレークポイント設定
- 基本変数（dt, App.time, App.frameCount）の確認
- ステップ実行とスタックトレース

### `debug_commands_custom.txt`
- シェーダーとパフォーマンスに特化したデバッグ
- Uniform変数の確認
- メモリ使用量とFPSの監視
- より詳細なデバッグ情報

## カスタムコマンドファイルの作成

### ファイル形式

```
# コメント行（# で始まる）
# 空行は無視されます

# MobDebugコマンドを1行ずつ記述
setb main.lua 103
run
exec print("デバッグ情報:", variable_name)
step
stack
quit
```

### 使用可能なMobDebugコマンド

- `setb <ファイル> <行番号>` - ブレークポイント設定
- `delb <ファイル> <行番号>` - ブレークポイント削除
- `run` - 実行継続
- `step` - ステップイン実行
- `over` - ステップオーバー実行
- `out` - ステップアウト実行
- `exec <Lua文>` - Lua文の実行
- `stack` - スタックトレース表示
- `quit` - デバッグ終了

### カスタムファイル例

```bash
# my_debug_scenario.txt というファイルを作成
cat > my_debug_scenario.txt << 'EOF'
# エディタ機能のデバッグ
setb ui/editor.lua 50
run

# エディタの状態確認
exec print("エディタテキスト長:", string.len(App.editor:getText()))
exec print("カーソル位置:", App.editor.cursor_line, App.editor.cursor_col)

step
stack
run
EOF

# 実行
./auto_debug_session.sh my_debug_scenario.txt
```

## ベストプラクティス

1. **段階的なデバッグ**
   - 1つのファイルで1つの機能に焦点を当てる
   - 複雑なシナリオは複数のファイルに分割

2. **コメントの活用**
   - 各セクションの目的をコメントで明記
   - デバッグ対象の機能や期待する結果を記述

3. **実行時間の考慮**
   - `auto_debug_session.sh`は30秒間で自動終了
   - 長時間のデバッグが必要な場合は`interactive_debug.sh`を使用

4. **ファイル命名規則**
   - `debug_commands_*.txt` の形式で命名
   - 目的が分かりやすい名前を使用（例：`debug_commands_shader.txt`）

## トラブルシューティング

### コマンドファイルが見つからない
```
エラー: デバッグコマンドファイルが見つかりません
→ ファイルが存在するか、ファイル名が正しいかを確認
```

### デバッグコマンドが実行されない
```
→ コメント行（#）や空行が正しく設定されているかを確認
→ MobDebugコマンドの構文が正しいかを確認
```

### Love2Dアプリケーションが起動しない
```
→ main.luaにMobDebugの初期化コードがあるかを確認
→ --debug フラグでLove2Dが起動できるかを確認
```