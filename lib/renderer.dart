import 'dart:web_gl';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

import 'package:rts_demo_client/model.dart';
import 'package:rts_demo_client/web_gl_debug.dart';

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

String myLoadShader(String name) {
  throw new Exception('this string should have been replaced by the transformer');
}

String myLoadModel(String name) {
  throw new Exception('the transformer did not work :-(');
}

class Renderer {
  RenderingContext _gl;
  Program _program;
  Buffer _buffer;

  Renderer(RenderingContext gl) {

    _gl = new DebugRenderingContext(gl)
      ..clearColor(158.0 / 255.0, 154.0 / 255.0, 65.0 / 255.0, 1.0)
      ..enable(DEPTH_TEST);
    
    String vshader = myLoadShader('simple.vert');
    String fshader = myLoadShader('simple.frag');
    _program = createProgram(_gl, vshader, fshader);

    _gl.useProgram(_program);
    
    _buffer = _getBuffer(_gl);

    assert(_gl.isProgram(_program));
    assert(_gl.isBuffer(_buffer));

    _setUpPointers();

    // uniforms
    // u_ViewMatrix

    Matrix4 mvp = _getProjectionMatrix() * _getViewMatrix();

    _gl.uniformMatrix4fv(_u('u_ViewMatrix'), false, mvp.storage);


    // u_LightColor
    _gl.uniform3fv(_u('u_LightColor'),
        new Vector3(1.0, 1.0, 1.0).storage);
    // u_LightPosition
    _gl.uniform3fv(_u('u_LightPosition'),
        new Vector3(100.0, 100.0, 100.0).storage);
    // u_AmbientLight
    _gl.uniform3fv(_u('u_AmbientLight'),
        new Vector3(0.05, 0.05, 0.05).storage);
  }

  void _setUpPointers() {
    int stride = 6 * Float32List.BYTES_PER_ELEMENT;

    _gl.bindBuffer(ARRAY_BUFFER, _buffer);
    _gl.vertexAttribPointer(_a('a_Position'), 3, FLOAT, false, stride, 0);
    _gl.enableVertexAttribArray(_a('a_Position'));


    int offsetNormals = 3 * Float32List.BYTES_PER_ELEMENT;

    _gl.vertexAttribPointer(_a('a_Normal'), 3, FLOAT, false, stride,
        offsetNormals);
    _gl.enableVertexAttribArray(_a('a_Normal'));
  }

  void render(double x, double y, Vector3 color) {

    // u_Color
    _gl.uniform3fv(_u('u_Color'), color.storage);

    // u_ModelMatrix
    Matrix4 modelMatrix = new Matrix4.translation(new Vector3(x, 0.0, y));

    _gl.uniformMatrix4fv(_u('u_ModelMatrix'), false, modelMatrix.storage);
        
    // u_NormalMatrix
    Matrix4 normalMatrix = new Matrix4.inverted(modelMatrix);
    normalMatrix.transpose();
    _gl.uniformMatrix4fv(_u('u_NormalMatrix'), false, normalMatrix.storage);

    _gl.drawArrays(TRIANGLES, 0, 6 * 2 * 3);
  }

  void clear() {
    _gl.clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT);
  }

  static Buffer _getBuffer(RenderingContext gl) {

    Model m = new Model.fromObj(myLoadModel('cube.obj'));

    Float32List positionsNormals = m.positionsAndNormalsToArr();

    Buffer buffer = gl.createBuffer();

    gl.bindBuffer(ARRAY_BUFFER, buffer);
    gl.bufferData(ARRAY_BUFFER, positionsNormals, STATIC_DRAW);

    return buffer;
  }

  int _a(String attribName) {
    final int attribLocation = _gl.getAttribLocation(_program,
        attribName);

    if (-1 == attribLocation) {
      throw new Exception('no such attribute: ' + attribName);
    }

    return attribLocation;
  }

  UniformLocation _u(String uniformName) {
    UniformLocation u = _gl.getUniformLocation(_program,
        uniformName);

    if (u == null) {
      throw new Exception("no such uniform: " + uniformName);
    }

    return u;
  }

  Matrix4 _getViewMatrix() {
    return makeViewMatrix(_getCamera(),
        _getLookAt(),
        new Vector3(0.0, 1.0, 0.0));
        
  }

  Vector3 _getLookAt() {
    return new Vector3(0.0, 0.0, 0.0);
  }

  Matrix4 _getProjectionMatrix() {

    double fovYRadians = 30.0 * degrees2Radians;
    double aspectRatio = 640.0 / 480.0;
    double zNear = 1.0;
    double zFar = 100.0;
    Matrix4 m = makePerspectiveMatrix(fovYRadians,
        aspectRatio, zNear, zFar);
    return m;
  }

  Vector3 _getCamera() {
    return new Vector3(30.0, 30.0, 30.0);
  }

  Vector3 ndcToWorld(Vector2 ndc) {
    var m = _getProjectionMatrix() * _getViewMatrix();
    m.invert();

    return (m * ndc).xyz;
  }

  Vector3 intersect(Vector2 ndc) {

    Vector3 view = _getLookAt() - _getCamera();
    view.normalize();

    Vector3 h = view.cross(new Vector3(0.0, 1.0, 0.0));
    h.normalize();
    
    Vector3 v = h.cross(view);
    v.normalize();

    double rad = 30.0 * degrees2Radians;
    double vLength = math.tan(rad / 2) * 1.0;
    double hLength = vLength * (640.0 / 480.0);
    
    v.scale(vLength);
    h.scale(hLength);

    Vector3 pos = _getCamera() + view + h.scaled(ndc.x) + v.scaled(ndc.y);

    Vector3 direction = pos - _getCamera();

    direction.normalize();


    double s = - _getCamera().y / direction.y;

    Vector3 where = _getCamera() + direction.scaled(s);

    return where;
  }

  bool castRay(Vector2 ndc, Vector3 entity) {
    Vector3 view = _getLookAt() - _getCamera();
    view.normalize();

    Vector3 h = view.cross(new Vector3(0.0, 1.0, 0.0));
    h.normalize();
    
    Vector3 v = h.cross(view);
    v.normalize();

    double rad = 30.0 * degrees2Radians;
    double vLength = math.tan(rad / 2) * 1.0;
    double hLength = vLength * (640.0 / 480.0);
    
    v.scale(vLength);
    h.scale(hLength);

    Vector3 pos = _getCamera() + view + h.scaled(ndc.x) + v.scaled(ndc.y);

    Vector3 direction = pos - _getCamera();

    direction.normalize();


    Vector3 l = entity - _getCamera();

    double tca = dot3(l, direction);

    double d = math.sqrt(math.pow(l.length, 2) - math.pow(tca, 2));

    return d < 1.0;
  }
}
