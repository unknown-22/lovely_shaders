# Lovely Shaders

Love2Dを使用したローカル動作のシェーダー開発環境。Shadertoyの機能をベースに、Love2Dの特性を活かした親しみやすいツール。

## 実行方法

```bash
love .
```

## フォント設定

指定フォント: `asset/font/UDEVGothic35HSJPDOC-Regular.ttf`
- エディタ: 14pt
- UI: 13pt
- フォントファイルが見つからない場合は自動的にデフォルトフォントにフォールバック

## Phase 1 MVP機能

✅ **実装完了**
- 基本的なテキストエディタ
- Shadertoy互換のUniform変数
- シンプルなファイル保存・読み込み
- 基本的なエラー表示
- 手動コンパイルボタン

## キーボードショートカット

- **F5**: シェーダーリロード
- **F11**: フルスクリーン切り替え
- **Ctrl+S**: 保存
- **Ctrl+O**: 開く
- **Ctrl+E**: エディタ表示切り替え
- **ESC**: 終了

## ファイル構造

```
lovely_shaders/
├── main.lua           # メインエントリーポイント
├── conf.lua           # Love2D設定
├── core/              # コア機能
│   ├── shader_manager.lua
│   └── file_manager.lua
├── ui/                # UI関連
│   ├── components.lua
│   └── editor.lua
└── shaders/           # シェーダーファイル
    └── default.glsl
```

## 次の実装予定（Phase 2）

- 入力チャンネルシステム（画像のみ）
- プリセット・テンプレート
- 画像エクスポート
- UIの改善