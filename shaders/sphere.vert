#version 330 core

layout(location = 0) in vec3 position;

layout(std140) uniform Camera
{
    mat4 U;         // P × V
    mat4 V;         // V
    mat3 F;         // F[0 ..< 3]
    vec3 position;  // F[3]
} camera;

void main()
{
    gl_Position  = camera.U * vec4(position, 1);
}
