# Lovely Shaders 仕様書

## 概要
Lovely Shaders - Love2Dを使用したローカル動作のシェーダー開発環境。Shadertoyの機能をベースに、Love2Dの特性を活かした親しみやすいツール。

## システム要件
- Love2D 11.5
- OpenGL ES 3.0対応のGPU
- 推奨解像度: 1280x720以上

## 主要機能

### 1. シェーダーエディタ
#### 1.1 エディタ機能
- **テキストエリア**: シンプルなテキスト入力エリア
- **行番号表示**: エラー位置の特定を容易に
- **手動コンパイル**: ボタンクリックでシェーダーをコンパイル・適用

#### 1.2 エラーハンドリング
- コンパイルエラーの詳細表示
- 警告メッセージの表示
- タイムスタンプ付きログ
- コンソールエリアでの一元管理

### 2. Shadertoy互換のUniform変数とシェーダー構造

#### 2.1 シェーダーテンプレート
```glsl
#version 300 es
precision highp float;

// 時間関連
uniform float iTime;           // シェーダー開始からの経過時間（秒）
uniform float iTimeDelta;      // 前フレームからの経過時間
uniform int iFrame;            // レンダリングフレーム番号

// 解像度
uniform vec3 iResolution;      // ビューポートの解像度（ピクセル）

// マウス入力
uniform vec4 iMouse;           // マウス座標 xy: 現在位置, zw: クリック位置

// 日付
uniform vec4 iDate;            // 年, 月, 日, 秒

// 入力チャンネル
uniform sampler2D iChannel0;   // 入力テクスチャ0
uniform sampler2D iChannel1;   // 入力テクスチャ1
uniform sampler2D iChannel2;   // 入力テクスチャ2
uniform sampler2D iChannel3;   // 入力テクスチャ3

// チャンネル解像度
uniform vec3 iChannelResolution[4]; // 各チャンネルの解像度

out vec4 fragColor;

// Shadertoy互換のメイン関数
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // ユーザーのシェーダーコードはここに記述
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}
```

#### 2.2 GLSL3の利点活用
- `texture()` 関数の統一使用（`texture2D()`は不要）
- 配列の動的インデックスアクセス
- ビット演算のフルサポート
- `uint` 型の使用可能

### 3. 入力チャンネルシステム

#### 3.1 対応入力タイプ
- **画像ファイル**: PNG, JPG, BMP対応
- **前フレームバッファ**: フィードバック効果用
- **ノイズテクスチャ**: 組み込みノイズテクスチャ

#### 3.2 チャンネル設定
- ファイル選択ダイアログでの入力設定
- ラップモード設定（Repeat/Clamp/Mirror）
- フィルタリング設定（Linear/Nearest）

### 4. プリセット・テンプレート

#### 4.1 基本テンプレート
- **Default**: 基本的なグラデーション
- **Raymarching**: レイマーチングの基本構造
- **2D Effects**: 2Dエフェクトのテンプレート
- **Audio Reactive**: オーディオ反応型のテンプレート

#### 4.2 ユーティリティ関数
```glsl
// ノイズ関数（GLSL3対応）
float hash(vec2 p);
float noise(vec2 p);
float noise(vec3 p);

// SDF関数
float sdBox(vec3 p, vec3 b);
float sdSphere(vec3 p, float r);
float opUnion(float d1, float d2);
float opSubtraction(float d1, float d2);

// 色空間変換
vec3 hsv2rgb(vec3 c);
vec3 rgb2hsv(vec3 c);

// 行列演算
mat2 rot2(float a);
mat3 rot3(vec3 axis, float angle);
```

### 5. ファイル管理

#### 5.1 プロジェクト形式
```
lovely-shaders-project/
├── shader.glsl      # メインシェーダーファイル
├── settings.json    # プロジェクト設定
├── assets/         # 使用する画像・音声ファイル
└── captures/       # キャプチャした画像・動画
```

#### 5.2 保存・読み込み
- プロジェクト単位での保存
- シェーダーコードのみのエクスポート

### 6. エクスポート機能

#### 6.1 画像エクスポート
- PNG形式での静止画保存
- 解像度指定可能（最大4K）

#### 6.2 スタンドアロン出力
- 独立したLove2Dプロジェクトとして出力
- 必要最小限のランタイムを含む

### 7. UI/UX

#### 7.1 デザインシステム

##### カラーパレット
```lua
-- ダークテーマベース
colors = {
    -- 背景色
    bg_primary   = {0.09, 0.09, 0.11, 1.0},  -- #171719
    bg_secondary = {0.12, 0.12, 0.14, 1.0},  -- #1F1F24
    bg_tertiary  = {0.16, 0.16, 0.18, 1.0},  -- #29292E
    
    -- テキスト色
    text_primary   = {0.95, 0.95, 0.96, 1.0},  -- #F2F2F5
    text_secondary = {0.60, 0.60, 0.64, 1.0},  -- #999AA3
    text_disabled  = {0.35, 0.35, 0.40, 1.0},  -- #595A66
    
    -- アクセント色
    accent_primary = {0.33, 0.60, 0.99, 1.0},  -- #5599FC
    accent_hover   = {0.40, 0.67, 1.00, 1.0},  -- #66AAFF
    accent_active  = {0.27, 0.50, 0.85, 1.0},  -- #4480D9
    
    -- ステータス色
    error   = {0.95, 0.26, 0.21, 1.0},  -- #F44336
    warning = {1.00, 0.76, 0.03, 1.0},  -- #FFC107
    success = {0.30, 0.69, 0.31, 1.0},  -- #4CAF50
    
    -- ボーダー
    border = {0.20, 0.20, 0.23, 1.0},   -- #33333A
}
```

##### スペーシングシステム
```lua
spacing = {
    xs = 4,   -- 最小マージン
    sm = 8,   -- 小マージン
    md = 16,  -- 標準マージン
    lg = 24,  -- 大マージン
    xl = 32,  -- 特大マージン
}
```

##### フォント
```lua
fonts = {
    -- 等幅フォント（エディタ用）
    mono = "fonts/JetBrainsMono-Regular.ttf",
    mono_size = 14,
    
    -- UIフォント
    ui = "fonts/Inter-Regular.ttf",
    ui_size = 13,
    ui_size_small = 11,
}
```

#### 7.2 レイアウト
```
┌─────────────────────────────────────┐
│  メニューバー (40px)                  │ bg_secondary
├─────────────┬───────────────────────┤
│             │                       │
│  シェーダー   │    プレビュー画面      │ bg_primary / bg_tertiary
│  エディタ     │                       │
│  (40%)      │    (60%)              │
│             │                       │
├─────────────┤                       │
│  コンソール   │                       │ bg: #0D0D0F
│  (140px)    │                       │
├─────────────┼───────────────────────┤
│  チャンネル   │    パラメータ          │ bg_secondary
│  設定        │    スライダー          │ (200px)
└─────────────┴───────────────────────┘
```

##### コンポーネントスタイル

**ボタン**
```lua
button = {
    bg = colors.bg_tertiary,
    bg_hover = colors.accent_primary,
    bg_active = colors.accent_active,
    text = colors.text_primary,
    border_radius = 6,
    padding = {x = spacing.md, y = spacing.sm},
    min_width = 80,
    height = 32,
}
```

**テキストエリア（エディタ）**
```lua
editor = {
    bg = colors.bg_primary,
    text = colors.text_primary,
    line_number_bg = colors.bg_secondary,
    line_number_text = colors.text_disabled,
    selection_bg = {0.33, 0.60, 0.99, 0.3},  -- accent with alpha
    cursor_color = colors.accent_primary,
    padding = spacing.md,
    line_height = 1.5,
}
```

**エラー表示**
```lua
error_panel = {
    bg = {0.95, 0.26, 0.21, 0.1},  -- error color with alpha
    border = colors.error,
    text = colors.error,
    padding = spacing.sm,
    margin_top = spacing.xs,
}
```

**コンソール**
```lua
console = {
    bg = {0.05, 0.05, 0.06, 1.0},  -- #0D0D0F
    header_bg = colors.bg_secondary,
    text_normal = colors.text_secondary,
    text_error = colors.error,
    text_warning = colors.warning,
    text_success = colors.success,
    padding = spacing.sm,
    line_height = 20,
    max_lines = 100,
}
```

**スライダー**
```lua
slider = {
    track_bg = colors.bg_tertiary,
    track_height = 4,
    handle_size = 16,
    handle_bg = colors.accent_primary,
    handle_bg_hover = colors.accent_hover,
    label_color = colors.text_secondary,
}
```

#### 7.3 アニメーション
```lua
-- シンプルなイージング（実装コストを抑える）
animations = {
    button_hover = 0.15,  -- 秒
    panel_toggle = 0.2,   -- 秒
}
```

#### 7.1 レイアウト
```
┌─────────────────────────────────────┐
│  メニューバー                         │
├─────────────┬───────────────────────┤
│             │                       │
│  シェーダー   │    プレビュー画面      │
│  エディタ     │                       │
│             │                       │
├─────────────┼───────────────────────┤
│  チャンネル   │    パラメータ          │
│  設定        │    スライダー          │
└─────────────┴───────────────────────┘
```

#### 7.4 操作方法

##### キーボードショートカット
- **F1**: ヘルプ表示
- **F5**: シェーダーリロード
- **F11**: フルスクリーン切り替え
- **Ctrl+S**: 保存
- **Ctrl+O**: 開く
- **Ctrl+E**: エディタ表示切り替え

##### UIボタン
- **保存ボタン**: プロジェクトの保存
- **開くボタン**: プロジェクトを開く
- **コンパイルボタン**: シェーダーのコンパイル・適用
- **リロードボタン**: シェーダーの再読み込み
- **フルスクリーンボタン**: フルスクリーン切り替え
- **エディタ切り替えボタン**: エディタの表示/非表示
- **ヘルプボタン**: ヘルプダイアログの表示

### 8. パフォーマンス機能

#### 8.1 統計情報表示
- FPS
- フレーム時間（ms）

#### 8.2 最適化オプション
- 解像度の動的調整
- フレームレート制限
- 低品質プレビューモード

### 9. 拡張機能

#### 9.1 マルチパスレンダリング
- 複数のレンダーターゲット対応
- バッファ間での相互参照

#### 9.2 カスタムUniform変数
- GUI経由でのfloat/vec2/vec3/vec4パラメータ追加
- スライダー、カラーピッカーでの調整

## 実装優先順位

### Phase 1（MVP）
1. 基本的なテキストエディタ
2. Shadertoy互換のUniform変数
3. シンプルなファイル保存・読み込み
4. 基本的なエラー表示
5. 手動コンパイルボタン

### Phase 2
1. 入力チャンネルシステム（画像のみ）
2. プリセット・テンプレート
3. 画像エクスポート
4. UIの改善

### Phase 3
1. カスタムUniform変数
2. パフォーマンス最適化
3. スタンドアロン出力

### Phase 4
1. マルチパスレンダリング
2. プラグインシステム

## 技術仕様

### 使用ライブラリ
- Love2D 11.5
- LuaFileSystem（ファイル操作用）
- json.lua（設定ファイル用）

### シェーダー仕様
- GLSL ES 3.0（#version 300 es）
- 頂点シェーダーは固定（全画面クワッド）
- フラグメントシェーダーのみ編集可能
- Shadertoy互換のmainImage関数形式

### パフォーマンス目標
- 1920x1080で60FPS維持（中程度の複雑さのシェーダー）
- エディタ表示時でも30FPS以上