# CLAUDE_common.md

英語で考え、返答はすべて日本語で行います。
*MUST* think in English and answer in Japanese.

## プロエジェクト概要

Lovely Shaders - Love2Dを使用したローカル動作のシェーダー開発環境。Shadertoyの機能をベースに、Love2Dの特性を活かした親しみやすいツール。

## コーディング規約

### 命名規則
- **変数・関数**: `camelCase`
- **定数**: `LOUD_SNAKE_CASE`
- **モジュール・テーブル**: `PascalCase`
- **プライベートメンバー**: `_privateMember`
- **ファイル**: `小文字`でオプションでアンダースコア使用

### コードフォーマット
- **インデント**: 4スペース
- **文字列**: 二重引用符 `"文字列"`
- **関数ドキュメント**: EmmyLua/LuaLS形式

### 基本原則
- **フォールバック処理の禁止**: 例外が発生した場合は、呼び出し側を修正する
- **後方互換性の廃止**: 修正時にフォールバックとして以前の仕様を残さない。古い呼び出しは呼び出し側のコードを修正する
- **最適な状態の維持**: コードは常に最適な状態を保つよう、不要な互換性コードは削除する
- **nilチェック**: すべての外部オブジェクトのフィールド/メソッドは存在確認後に使用
- **戻り値保証**: ファサードパターンでは戻り値の明示的返却必須、nil返却は成功/失敗判定を破綻させる
- **requireの括弧**: `require`は括弧書きで使用する(ex. `local Module = require("path.to.module")`)
- **EmmyLua/LuaLSアノテーション**: 全ての関数、クラス、ファイルに包括的なアノテーションを追加する

## コード品質管理

### 必須チェック
- **Lua言語サーバー**: `lua-language-server --check .`
- **Selene**: `selene .`
- **目標**: 警告・エラーを0個にする

## Love2D開発コマンド

```bash
# Love2Dゲームを実行
love .

# 特定の設定で実行
love . --config=debug
```

## ドキュメント品質基準

### EmmyLua/LuaLSアノテーション必須項目
- **ファイルヘッダー**: `@file`、`@brief`、`@details`
- **クラス定義**: `@class`、`@field`（継承関係も含む）
- **関数定義**: `@brief`、`@param`、`@return`
- **型定義**: `@type`（変数宣言時）

### アノテーション例
```lua
---@file path/to/module.lua
---@brief モジュールの簡潔な説明
---@details モジュールの詳細な説明

---@class MyClass
---@field myField string フィールドの説明
local MyClass = {}

---@brief 関数の簡潔な説明
---@param param1 string パラメータの説明
---@param param2 number パラメータの説明
---@return boolean 戻り値の説明
function MyClass.myFunction(param1, param2)
    -- 実装
    return true
end
```

## リソース管理のベストプラクティス

### 基本原則
- **エラーハンドリング**: リソース読み込み失敗時の適切な処理
- **メモリ管理**: 不要なリソースの適切な解放
- **パフォーマンス**: リソースの重複読み込み防止

### Love2D標準API使用例
```lua
-- フォント管理
local font = love.graphics.newFont("assets/fonts/font.ttf", 24)
local textObj = love.graphics.newText(font, "Hello World")

-- 画像・描画管理
local image = love.graphics.newImage("assets/images/sprite.png")
love.graphics.draw(image, x, y)
```

## テスト戦略

### 推奨アプローチ
- **ユニットテスト**: 個別関数・クラステスト
- **統合テスト**: コンポーネント間連携テスト
- **エラーケーステスト**: 例外処理テスト
- **パフォーマンステスト**: 処理速度・メモリ使用量テスト

### Love2Dモック環境
テスト環境では以下のLove2D APIをモックする必要があります：
- `love.graphics` (フォント、画像、描画)
- `love.audio` (音声ソース)
- `love.joystick` (ゲームパッド)
- `love.mouse` (マウス入力)
- `love.filesystem` (ファイル存在確認)

## 開発支援ツール

### 静的解析
```bash
# Lua言語サーバーによるチェック
lua-language-server --check .

# Seleneによるリンティング
selene .
```

### デバッグ
- **print文デバッグ**: `print()`による基本的なデバッグ
- **Love2Dコンソール**: `love.graphics.print()`による画面表示デバッグ
- **外部デバッガー**: ZeroBrane Studio、VS Code拡張など

## パフォーマンス最適化

### 一般的な最適化手法
- **描画バッチング**: 同一テクスチャの一括描画
- **オブジェクトプール**: 頻繁な生成・破棄オブジェクトの再利用
- **ダーティフラグ**: 変更検知による無駄な処理削減
- **空間分割**: 衝突判定の効率化

### Love2D固有の最適化
- **Canvas使用**: 複雑な描画の事前レンダリング
- **SpriteBatch**: 大量スプライトの効率的描画
- **ImageData最適化**: ピクセル操作の効率化

## セキュリティとエラーハンドリング

### 基本原則
- **入力検証**: 外部入力の必須検証
- **例外処理**: `pcall`/`xpcall`による安全な関数呼び出し
- **リソース保護**: 存在しないファイル・フォントへの対応
- **クラッシュ防止**: 予期しないエラーからの回復機能

### エラーハンドリング例
```lua
-- 安全なリソース読み込み
local function safeLoadImage(path)
    local success, result = pcall(love.graphics.newImage, path)
    if success then
        return result
    else
        print("Warning: Failed to load image: " .. path)
        return nil -- またはデフォルト画像
    end
end
```
