import 'dart:web_gl';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

import 'package:rts_demo_client/model.dart';
import 'package:rts_demo_client/web_gl_debug.dart';
import 'package:rts_demo_client/mesh.dart';
import 'package:rts_demo_client/glutils.dart';

class Renderer {
  RenderingContext _gl;
  Program _program;

  Renderer(RenderingContext gl) {

    _gl = new DebugRenderingContext(gl)
      ..clearColor(158.0 / 255.0, 154.0 / 255.0, 65.0 / 255.0, 1.0)
      ..enable(DEPTH_TEST);
    
    String vshader = myLoadShader('simple.vert');
    String fshader = myLoadShader('simple.frag');
    _program = createProgram(_gl, vshader, fshader);

    assert(_gl.isProgram(_program));
  }

  void _setUpPointers() {
    int stride = 6 * Float32List.BYTES_PER_ELEMENT;

    _gl.vertexAttribPointer(_a('a_Position'), 3, FLOAT, false, stride, 0);
    _gl.enableVertexAttribArray(_a('a_Position'));


    int offsetNormals = 3 * Float32List.BYTES_PER_ELEMENT;

    _gl.vertexAttribPointer(_a('a_Normal'), 3, FLOAT, false, stride,
        offsetNormals);
    _gl.enableVertexAttribArray(_a('a_Normal'));
  }

  void render(Matrix4 projectionMatrix, Matrix4 viewMatrix, Matrix4 modelMatrix, double angle, Vector3 color, Mesh mesh) {

    _gl.useProgram(_program);

    Matrix4 mvp = projectionMatrix * viewMatrix;

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

    // u_Color
    _gl.uniform3fv(_u('u_Color'), color.storage);

    _gl.uniformMatrix4fv(_u('u_ModelMatrix'), false, modelMatrix.storage);
        
    // u_NormalMatrix
    Matrix4 normalMatrix = new Matrix4.inverted(modelMatrix);
    normalMatrix.transpose();
    _gl.uniformMatrix4fv(_u('u_NormalMatrix'), false, normalMatrix.storage);

    _gl.bindBuffer(ARRAY_BUFFER, mesh.buffer);
    _setUpPointers();
    _gl.drawArrays(TRIANGLES, 0, mesh.size);
  }

  void clear() {
    _gl.clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT);
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

}
