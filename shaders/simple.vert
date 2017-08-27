#ifdef GL_ES
precision mediump float;
#endif

attribute vec4 a_Position;
//attribute vec4 a_Color;
attribute vec4 a_Normal;

//uniform vec3 u_AmbientLightColor;
//uniform vec3 u_LightDirection;

uniform vec3 u_Color;
uniform mat4 u_ViewMatrix;
uniform mat4 u_ModelMatrix;
uniform mat4 u_NormalMatrix;

varying vec3 v_Normal;
varying vec3 v_Position;
varying vec4 v_Color;


void main() {
  gl_Position = (u_ViewMatrix * u_ModelMatrix) * a_Position;

  v_Position = vec3(u_ModelMatrix * a_Position);

  v_Normal = normalize(vec3(u_NormalMatrix * a_Normal));

  v_Color = vec4(u_Color, 1.0);
}
