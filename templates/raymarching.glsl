// Love2D互換レイマーチングシェーダー

uniform float iTime;
uniform vec3 iResolution;
uniform vec4 iMouse;

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float map(vec3 p) {
    // 回転する球体
    vec3 rotatedP = p;
    rotatedP.xz = mat2(cos(iTime), -sin(iTime), sin(iTime), cos(iTime)) * p.xz;
    return sdSphere(rotatedP, 1.0);
}

vec3 getNormal(vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        map(p + vec3(eps, 0.0, 0.0)) - map(p - vec3(eps, 0.0, 0.0)),
        map(p + vec3(0.0, eps, 0.0)) - map(p - vec3(0.0, eps, 0.0)),
        map(p + vec3(0.0, 0.0, eps)) - map(p - vec3(0.0, 0.0, eps))
    ));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    vec3 ro = vec3(0.0, 0.0, 3.0);
    vec3 rd = normalize(vec3(uv, -1.0));
    
    float t = 0.0;
    for (int i = 0; i < 64; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        if (d < 0.01) break;
        t += d;
        if (t > 10.0) break;
    }
    
    vec3 col = vec3(0.1, 0.1, 0.2);
    
    if (t < 10.0) {
        vec3 p = ro + rd * t;
        vec3 n = getNormal(p);
        col = vec3(0.5) + 0.5 * n;
        
        // 簡単なライティング
        vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
        float NdotL = max(0.0, dot(n, lightDir));
        col *= NdotL * 0.7 + 0.3;
    }
    
    fragColor = vec4(col, 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 fragColor;
    mainImage(fragColor, screen_coords);
    return fragColor;
}