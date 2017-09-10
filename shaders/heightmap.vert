#ifdef GL_ES
precision mediump float;
#endif

uniform mat4 u_ViewMatrix;


attribute float a_x;
attribute float a_y;
attribute float a_height;
attribute float extra;

varying float x;
varying float y;
varying float height;

void main() {

  x = a_x;
  y = a_y;
  height = a_height;

  vec4 pos = vec4(a_x, extra + a_height, a_y, 1.0);

  gl_Position = u_ViewMatrix * pos;
}
