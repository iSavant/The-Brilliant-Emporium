#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float time;
    vec2 res;
    float cell;
    float runes;
};

layout(binding = 1) uniform sampler2D oldTex;
layout(binding = 2) uniform sampler2D newTex;
layout(binding = 3) uniform sampler2D atlas;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 px = uv * res;
    vec2 c = floor(px / cell);
    vec2 cuv = (c + 0.5) * cell / res;
    vec2 local = fract(px / cell);

    float h1 = hash(c + 7.3);
    float h2 = hash(c + 41.1);

    float spread  = smoothstep(0.0, 0.48, progress) * 1.1;
    float resolve = smoothstep(0.58, 1.0, progress) * 1.1;
    float inInk = smoothstep(h1, h1 + 0.06, spread);
    float inNew = smoothstep(h2, h2 + 0.06, resolve);

    float flash = (smoothstep(h1, h1 + 0.03, spread) - smoothstep(h1 + 0.03, h1 + 0.12, spread))
                + (smoothstep(h2, h2 + 0.03, resolve) - smoothstep(h2 + 0.03, h2 + 0.12, resolve));

    float flick = step(0.42, progress) * step(progress, 0.72);
    float r = floor(hash(c + floor(time) * flick * 0.37) * runes);
    float g = texture(atlas, vec2((r + local.x) / runes, local.y)).a;

    float m = smoothstep(0.45, 0.62, progress);
    vec3 cellCol = mix(texture(oldTex, cuv).rgb, texture(newTex, cuv).rgb, m);
    cellCol = min(cellCol * 1.6 + 0.08, vec3(1.0));
    vec3 ink = vec3(0.016, 0.02, 0.024);
    vec3 runeLayer = mix(ink, cellCol, g);

    vec3 col = mix(texture(oldTex, uv).rgb, runeLayer, inInk);
    col = mix(col, texture(newTex, uv).rgb, inNew);

    vec3 flame = vec3(0.73, 0.72, 0.71);
    col += flame * flash * 0.45;

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
