#version 300 es
precision highp float;

// 標準Shadertoy Uniform変数
uniform float iTime;
uniform vec3 iResolution;
uniform vec4 iMouse;

// カスタムUniform変数のサンプル
uniform float intensity;      // 強度調整用float
uniform vec2 center;          // 中心座標用vec2
uniform vec3 colorTint;       // 色調整用vec3
uniform vec4 gradientColors;  // グラデーション色用vec4

out vec4 fragColor;

// 2Dでの回転行列
mat2 rot2(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

// ノイズ関数
float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // 正規化座標
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
    
    // カスタムUniform変数を使用した効果
    
    // 1. centerを使用した中心からの距離計算
    vec2 centeredP = p - center;
    float dist = length(centeredP);
    
    // 2. intensityを使用した時間スケール調整
    float t = iTime * intensity;
    
    // 3. 回転効果
    vec2 rotatedP = rot2(t * 0.5) * centeredP;
    
    // 4. ノイズパターン生成
    float n1 = noise(rotatedP * 5.0 + t);
    float n2 = noise(rotatedP * 10.0 - t * 0.7);
    float n3 = noise(rotatedP * 20.0 + t * 1.2);
    
    // 5. 複合ノイズ
    float finalNoise = n1 * 0.5 + n2 * 0.3 + n3 * 0.2;
    
    // 6. 距離による減衰
    float falloff = 1.0 - smoothstep(0.0, 1.5, dist);
    
    // 7. colorTintを使用した色調整
    vec3 baseColor = colorTint * finalNoise * falloff;
    
    // 8. gradientColorsを使用したグラデーション
    vec3 gradientColor = mix(gradientColors.rgb, gradientColors.rbg, uv.y);
    
    // 9. 最終色の合成
    vec3 finalColor = mix(baseColor, gradientColor, 0.3);
    
    // 10. intensityによる全体の明度調整
    finalColor *= (0.5 + intensity * 0.5);
    
    // 11. マウス位置による効果
    vec2 mousePos = iMouse.xy / iResolution.xy;
    float mouseEffect = 1.0 - smoothstep(0.0, 0.3, distance(uv, mousePos));
    finalColor += mouseEffect * 0.2 * vec3(1.0, 0.8, 0.6);
    
    fragColor = vec4(finalColor, 1.0);
}

void main() {
    mainImage(fragColor, gl_FragCoord.xy);
}