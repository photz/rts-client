import 'dart:web_gl';
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import 'package:rts_demo_client/glutils.dart';
import 'package:rts_demo_client/web_gl_debug.dart';
import 'package:rts_demo_client/heightmap.dart';

class TerrainRenderer {

  RenderingContext _gl;
  Program _program;
  Heightmap _heightmap;
  Buffer _buffer;

  TerrainRenderer(RenderingContext gl, Heightmap this._heightmap) {
    _gl = new DebugRenderingContext(gl);

    String vshader = myLoadShader('heightmap.vert');
    String fshader = myLoadShader('heightmap.frag');
    _program = createProgram(_gl, vshader, fshader);
    _gl.useProgram(_program);
    assert(_gl.isProgram(_program));
    _buffer = _bufferHeightmap(_heightmap);
    assert(_gl.isBuffer(_buffer));

    int heightAttr = _a('a_height');
    print('height attr: ' + heightAttr.toString());

    int xAttr = _a('a_x');
    print('x attr: ' + xAttr.toString());

    int yAttr = _a('a_y');
    print('y attr: ' + yAttr.toString());
  }

  render(Matrix4 projectionMatrix, Matrix4 viewMatrix) {
    _gl.useProgram(_program);

    Matrix4 matrix = projectionMatrix * viewMatrix;

    _gl.uniformMatrix4fv(_u('u_ViewMatrix'), false, matrix.storage);

    _setUpPointers(_buffer);

    _gl.drawArrays(TRIANGLES, 0, _heightmap.size);
  }

  _setUpPointers(buffer) {
    _gl.bindBuffer(ARRAY_BUFFER, buffer);

    const int stride = 3 * Float32List.BYTES_PER_ELEMENT;

    _gl.vertexAttribPointer(_a('a_x'), 1, FLOAT, false, stride, 0);
    _gl.enableVertexAttribArray(_a('a_x'));

    _gl.vertexAttribPointer(_a('a_y'), 1, FLOAT, false, stride,
        1 * Float32List.BYTES_PER_ELEMENT);
    _gl.enableVertexAttribArray(_a('a_y'));

    _gl.vertexAttribPointer(_a('a_height'), 1, FLOAT, false, stride,
        2 * Float32List.BYTES_PER_ELEMENT);
    _gl.enableVertexAttribArray(_a('a_height'));

  }

  Buffer _bufferHeightmap(Heightmap heightmap) {
    Buffer buffer = _gl.createBuffer();
    _gl.bindBuffer(ARRAY_BUFFER, buffer);
    _gl.bufferData(ARRAY_BUFFER, heightmap.export(), STATIC_DRAW);
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

}
