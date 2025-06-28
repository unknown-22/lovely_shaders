// Love2D互換シェーダー（Shadertoy形式をベース）

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

// 入力チャンネル（Phase 2で実装予定）
// uniform sampler2D iChannel0;   // 入力テクスチャ0
// uniform sampler2D iChannel1;   // 入力テクスチャ1
// uniform sampler2D iChannel2;   // 入力テクスチャ2
// uniform sampler2D iChannel3;   // 入力テクスチャ3

// チャンネル解像度（Phase 2で実装予定）
// uniform vec3 iChannelResolution[4]; // 各チャンネルの解像度

// Shadertoy互換のメイン関数
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // 正規化座標を計算 (0.0-1.0)
    vec2 uv = fragCoord / iResolution.xy;
    
    // 中心を原点とした座標系 (-1.0 to 1.0)
    vec2 p = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
    
    // 時間による色の変化
    vec3 col = 0.5 + 0.5 * cos(iTime + uv.xyx + vec3(0, 2, 4));
    
    // 中心からの距離による効果
    float dist = length(p);
    col *= 1.0 - smoothstep(0.0, 1.0, dist);
    
    // 波紋効果
    float ripple = sin(dist * 20.0 - iTime * 5.0) * 0.1;
    col += ripple;
    
    fragColor = vec4(col, 1.0);
}

// Love2D用effectエントリーポイント
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 fragColor;
    mainImage(fragColor, screen_coords);
    return fragColor;
}