#version 330 core

layout(location = 0) in vec3 position;

layout(std140) uniform Camera
{
    mat4 U;
    mat4 V;
    mat4 F;
    
    // projection parameters 
    vec3 a;
    vec3 b;
    
    // view parameters
    vec3 position;
} camera;

void main()
{
    gl_Position  = camera.U * vec4(position, 1);
}
