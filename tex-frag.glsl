#version 330

in vec2 uv;

uniform sampler2D Texture;

out vec4 f_color;

vec3 preprocess(vec3 x) {
    vec3 c = clamp(x, 0, 1);
    float pwd = 1/2.2;
    vec3 p = vec3(pow(c.x,pwd), pow(c.y, pwd), pow(c.z, pwd));
    return (p * 255 + 0.5) / 255.0;
}

void main() {
    f_color = vec4(preprocess(texture(Texture, uv).xyz), 1);
}