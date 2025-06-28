// Love2D互換2Dエフェクトシェーダー

uniform float iTime;
uniform vec3 iResolution;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(mix(hash(i + vec2(0.0, 0.0)), 
                   hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), 
                   hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    
    // 波のような歪み
    vec2 offset = vec2(
        sin(uv.y * 10.0 + iTime) * 0.02,
        cos(uv.x * 10.0 + iTime) * 0.02
    );
    
    vec2 distortedUV = uv + offset;
    
    // 時間による色の変化
    vec3 col = vec3(
        0.5 + 0.5 * sin(distortedUV.x * 6.28 + iTime),
        0.5 + 0.5 * sin(distortedUV.y * 6.28 + iTime * 1.1),
        0.5 + 0.5 * sin((distortedUV.x + distortedUV.y) * 3.14 + iTime * 1.3)
    );
    
    // ノイズを追加
    float n = noise(fragCoord * 0.01 + iTime * 0.5);
    col += n * 0.1;
    
    // 中心からの距離による効果
    vec2 center = vec2(0.5);
    float dist = length(uv - center);
    col *= 1.0 - smoothstep(0.3, 0.8, dist);
    
    fragColor = vec4(col, 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 fragColor;
    mainImage(fragColor, screen_coords);
    return fragColor;
}