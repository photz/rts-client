#ifdef GL_ES
precision mediump float;
#endif

uniform mat4 u_ViewMatrix;
uniform mat4 u_NormalMatrix;
uniform vec3 u_LightColor;
uniform vec3 u_LightPosition;
uniform vec3 u_AmbientLight;

attribute float a_x;
attribute float a_y;
attribute float a_height;
attribute vec3 a_vn;

varying float x;
varying float y;
varying float height;
varying vec3 v_normal;
varying vec3 v_Position;

void main() {
  vec4 pos = vec4(a_x, a_height, a_y, 1.0);
  v_Position = pos.xyz;
  v_normal = normalize(vec3(u_NormalMatrix * vec4(a_vn, 1.0)));
  x = a_x;
  y = a_y;
  height = a_height;



  gl_Position = u_ViewMatrix * pos;
}
