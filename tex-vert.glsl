#version 330

in vec2 in_vert;

out vec2 uv;

void main() {
    gl_Position = vec4(in_vert, 0, 1);
    uv = (1 + in_vert) / 2;
}