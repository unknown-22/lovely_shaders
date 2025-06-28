---@file templates/templates.lua
---@brief テンプレート設定ファイル
---@details テンプレートのメタデータを定義

return {
    {
        name = "Default",
        description = "基本的なグラデーション",
        category = "基本",
        file = "default.glsl"
    },
    {
        name = "Raymarching",
        description = "レイマーチングの基本構造",
        category = "3D",
        file = "raymarching.glsl"
    },
    {
        name = "2D Effects",
        description = "2Dエフェクトのテンプレート",
        category = "2D",
        file = "2d_effects.glsl"
    },
    {
        name = "Texture Sampling",
        description = "UV座標変形のデモ",
        category = "2D",
        file = "texture_sampling.glsl"
    },
    {
        name = "Fractal",
        description = "フラクタルパターン",
        category = "フラクタル",
        file = "fractal.glsl"
    },
    {
        name = "Plasma",
        description = "プラズマエフェクト",
        category = "エフェクト",
        file = "plasma.glsl"
    },
    {
        name = "Channel Demo",
        description = "チャンネルテクスチャのデモ",
        category = "チャンネル",
        file = "channel_demo.glsl"
    }
}