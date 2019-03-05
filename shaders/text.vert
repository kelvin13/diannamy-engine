#version 330 core

layout(location = 0) in vec2 anchor;
layout(location = 1) in vec2 offset;
layout(location = 2) in vec4 color;

layout(std140) uniform Display 
{
    vec2 frame_a;
    vec2 frame_b;
    vec2 viewport;
} display;

out Vertex
{
    vec2 anchor;
    vec4 color;
} vertex;

void main()
{
    gl_Position   = vec4(2 * vec2(offset.x, display.viewport.y - offset.y) / display.viewport - 1, 1, 1);
    vertex.anchor = anchor;
    vertex.color  = color;
}