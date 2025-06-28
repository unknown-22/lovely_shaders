// Love2D互換テクスチャサンプリングシェーダー

uniform float iTime;
uniform vec3 iResolution;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / iResolution.xy;
    
    // UV座標の変形
    vec2 center = vec2(0.5);
    vec2 dir = uv - center;
    float dist = length(dir);
    
    // 回転効果
    float angle = atan(dir.y, dir.x) + iTime * 0.5;
    vec2 rotatedUV = center + dist * vec2(cos(angle), sin(angle));
    
    // 波のような歪み
    rotatedUV += 0.02 * sin(rotatedUV * 20.0 + iTime);
    
    // 基本的なグラデーション（テクスチャサンプリングのデモとして）
    vec3 col = vec3(
        0.5 + 0.5 * sin(rotatedUV.x * 6.28 + iTime),
        0.5 + 0.5 * sin(rotatedUV.y * 6.28 + iTime * 1.1),
        0.5 + 0.5 * sin((rotatedUV.x + rotatedUV.y) * 3.14 + iTime * 1.3)
    );
    
    // UV座標をテクスチャ座標として使用する場合のサンプル
    // vec4 texColor = Texel(texture, rotatedUV);
    // col = texColor.rgb;
    
    // ビネット効果
    float vignette = 1.0 - smoothstep(0.3, 0.8, dist);
    col *= vignette;
    
    // コントラスト調整
    col = pow(col, vec3(1.2));
    
    return vec4(col, 1.0);
}