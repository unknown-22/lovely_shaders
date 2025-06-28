// Love2D互換フラクタルシェーダー

uniform float iTime;
uniform vec3 iResolution;

vec2 complexMul(vec2 a, vec2 b) {
    return vec2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

int mandelbrot(vec2 c) {
    vec2 z = vec2(0.0);
    for (int i = 0; i < 100; i++) {
        if (length(z) > 2.0) return i;
        z = complexMul(z, z) + c;
    }
    return 100;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv *= 2.0;
    uv += vec2(-0.5, 0.0);
    
    // ズーム効果
    float zoom = 1.0 + 0.5 * sin(iTime * 0.1);
    uv /= zoom;
    
    // 時間による移動
    uv += vec2(sin(iTime * 0.05) * 0.1, cos(iTime * 0.03) * 0.1);
    
    int iterations = mandelbrot(uv);
    float t = float(iterations) / 100.0;
    
    // カラフルな色付け
    vec3 col = vec3(
        0.5 + 0.5 * sin(t * 6.28 + iTime),
        0.5 + 0.5 * sin(t * 6.28 + iTime + 2.094),
        0.5 + 0.5 * sin(t * 6.28 + iTime + 4.188)
    );
    
    // セット内部は黒
    if (iterations == 100) {
        col = vec3(0.0);
    } else {
        // エッジを強調
        float edge = float(iterations) / 10.0;
        col *= 1.0 + edge * 0.5;
    }
    
    // 全体の明度調整
    col = pow(col, vec3(0.8));
    
    fragColor = vec4(col, 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 fragColor;
    mainImage(fragColor, screen_coords);
    return fragColor;
}