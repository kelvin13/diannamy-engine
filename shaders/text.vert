#version 330 core

layout(location = 0) in vec2 position;
layout(location = 1) in vec2 uv;
layout(location = 2) in vec4 color;

uniform vec2 viewport;

out Vertex
{
    vec2 uv;
    vec4 color;
} vertex;

void main()
{
    gl_Position  = vec4(2 * position / viewport - 1, 0, 1);
    vertex.uv    = uv;
    vertex.color = color;
}
