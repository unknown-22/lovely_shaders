// Love2D互換プラズマエフェクトシェーダー

uniform float iTime;
uniform vec3 iResolution;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 p = (fragCoord - 0.5 * iResolution.xy) / min(iResolution.x, iResolution.y);
    
    // プラズマエフェクト
    float plasma = sin(p.x * 10.0 + iTime) +
                   sin(p.y * 10.0 + iTime * 1.1) +
                   sin((p.x + p.y) * 10.0 + iTime * 1.2) +
                   sin(sqrt(p.x * p.x + p.y * p.y) * 10.0 + iTime * 1.3);
    
    plasma /= 4.0;
    
    // 色の変換
    vec3 col = vec3(
        0.5 + 0.5 * sin(plasma * 3.14159 + iTime),
        0.5 + 0.5 * sin(plasma * 3.14159 + iTime + 2.094),
        0.5 + 0.5 * sin(plasma * 3.14159 + iTime + 4.188)
    );
    
    fragColor = vec4(col, 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 fragColor;
    mainImage(fragColor, screen_coords);
    return fragColor;
}