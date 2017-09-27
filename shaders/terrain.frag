#ifdef GL_ES
precision mediump float;
#endif

uniform vec3 u_LightColor;
uniform vec3 u_LightPosition;
uniform vec3 u_AmbientLight;

varying float x;
varying float y;
varying float height;
varying vec3 v_Position;
varying vec3 v_normal;

void main() {

  vec4 border = vec4(0.0 / 255.0,
                     0.0 / 255.0,
                     0.0 / 255.0,
                     1.0);

  vec4 fields = vec4(158.0 / 255.0, 
                     154.0 / 255.0, 
                     65.0 / 255.0,
                     1.0);

  /*float d = 0.01;*/

  /* if (false && x - floor(x) < d || */
  /*     ceil(x) - x < d || */
  /*     y - floor(y) < d || */
  /*     ceil(y) - y < d) { */

  /*   gl_FragColor = border; */
  /* } */
  /* else { */
    vec3 normal = normalize(v_normal);

    vec3 lightDirection = normalize(u_LightPosition - v_Position);

    float d = max(dot(lightDirection, normal), 0.0);

    vec3 diffuse = u_LightColor * fields.rgb * d;

    vec3 ambient = u_AmbientLight * fields.rgb;

    gl_FragColor = vec4(diffuse + ambient, fields.a) + (vec4(0.1 * u_LightColor, 0.0));

  /* } */

}

