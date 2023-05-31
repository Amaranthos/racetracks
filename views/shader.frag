#version 330 core

uniform vec3 colour;

out vec3 out_color;

void main() {
  out_color = colour;
}