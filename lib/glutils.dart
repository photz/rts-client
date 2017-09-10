import 'dart:web_gl';


String myLoadShader(String name) {
  throw new Exception('this string should have been replaced by the transformer');
}

Program createProgram(RenderingContext gl,
    String vShaderSource, String fShaderSource) {

  Shader vShader = loadShader(gl, RenderingContext.VERTEX_SHADER,
      vShaderSource);

  Shader fShader = loadShader(gl, RenderingContext.FRAGMENT_SHADER,
      fShaderSource);

  Program program = gl.createProgram();

  gl.attachShader(program, vShader);
  gl.attachShader(program, fShader);
  gl.linkProgram(program);
  print(gl.getProgramInfoLog(program));
  return program;
}

Shader loadShader(RenderingContext gl, int type, String source) {
  Shader shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  print(gl.getShaderInfoLog(shader));
  return shader;
}
