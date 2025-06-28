// Love2D互換シェーダー（基本グラデーション）

uniform float iTime;
uniform vec3 iResolution;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    
    vec3 col = vec3(uv.x, uv.y, 0.5 + 0.5 * sin(iTime));
    
    fragColor = vec4(col, 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 fragColor;
    mainImage(fragColor, screen_coords);
    return fragColor;
}