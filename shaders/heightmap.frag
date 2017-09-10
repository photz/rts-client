#ifdef GL_ES
precision mediump float;
#endif

varying float x;
varying float y;
varying float height;

void main() {

  vec4 border = vec4(0.0 / 255.0,
                     0.0 / 255.0,
                     0.0 / 255.0,
                     1.0);

  vec4 fields = vec4(158.0 / 255.0, 
                     154.0 / 255.0, 
                     65.0 / 255.0,
                     1.0);

  float d = 0.01;

  if (x - floor(x) < d ||
      ceil(x) - x < d ||
      y - floor(y) < d ||
      ceil(y) - y < d) {

    gl_FragColor = border;
  }
  else {
    gl_FragColor = fields;
  }

}

