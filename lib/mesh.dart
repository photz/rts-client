import 'dart:web_gl';
import 'dart:typed_data';

import 'package:rts_demo_client/model.dart';




String myLoadModel(String name) {
  throw new Exception('the transformer did not work :-(');
}

class Mesh {
  int get size => _data.length / 6;
  Buffer get buffer => _buffer;

  Float32List _data;
  Buffer _buffer;

  Mesh(RenderingContext gl, Model model) {
    _data = model.positionsAndNormalsToArr();
    
    _buffer = gl.createBuffer();

    gl.bindBuffer(ARRAY_BUFFER, _buffer);
    gl.bufferData(ARRAY_BUFFER, _data, STATIC_DRAW);
  }

}