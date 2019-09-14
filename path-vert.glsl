#version 330

in vec2 in_vert;

uniform vec2 pixel_dim;

out vec3 r;
out vec2 uv;

void main() {
    gl_Position = vec4(in_vert, 0, 1);
    r = vec3(in_vert, 1);
    uv = (1 + in_vert) / 2;
}