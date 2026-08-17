#version 330 core
out vec4 FragColor;

in vec3 ourColor;
in vec2 TexCoord;

uniform sampler2D reiTexture;
uniform sampler2D shinjiTexture;
uniform float mixArg;



void main()
{
    FragColor = mix(texture(reiTexture, 1 - TexCoord), texture(shinjiTexture, 1 - TexCoord), mixArg);
}
