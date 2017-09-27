import 'dart:math' as math;
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

class Heightmap {
  
  List<double> _bytes;
  int _size;
  int _theSize;

  int get size => _theSize * 5;

  Heightmap(this._bytes) {
    double x = math.log(_bytes.length) / math.log(2.0);

    if (x.truncateToDouble() != x) {
      throw new Exception('the map must be a square');
    }

    _size = math.sqrt(_bytes.length).toInt();
  }

  double height(double x, double y) {
    double xr = x - x.floorToDouble();
    double yr = y - y.floorToDouble();

    bool left = (xr + yr) < 1.0;

    int ax;

    if (left) {
      // a
      // b c
      ax = x.floor();
    }
    else {
      // _ a
      // b c
      ax = x.ceil();
    }

    int ay = y.floor();
    double aHeight = _get(ax, ay);

    int bx = x.floor();
    int by = y.ceil();
    double bHeight = _get(bx, by);

    int cx = x.ceil();
    int cy = by;
    double cHeight = _get(cx, cy);

    Vector3 ba = new Vector3((ax - bx).toDouble(),
        aHeight - bHeight, (ay - by).toDouble());
    
    Vector3 bc = new Vector3((cx - bx).toDouble(),
        cHeight - bHeight, (cy - by).toDouble());

    Vector3 res = ba.scaled(yr) + bc.scaled(xr);
    res.y += bHeight;
    return res.y;
  }

  Vector3 vertexNormal(int x, int y) {
    

    Vector3 avg = new Vector3.zero();
    int count = 0;

    if (0 < x && 0 < y) {
      avg += normal(x.toDouble() - 0.4, y.toDouble() - 0.4);
      count++;
    }

    if (x < _size - 1) {

    }

    if (y < _size - 1) {
      //avg += normal(x + 0.4, y + 0.4);
    }

    if (x < _size - 1 && y < _size - 1) {
      avg += normal(x.toDouble() + 0.4, y.toDouble() + 0.4);
      count++;
    }

    return avg / count.toDouble();
  }

  Vector3 normal(double x, double y) {
    double xr = x - x.floorToDouble();
    double yr = y - y.floorToDouble();

    bool left = (xr + yr) < 1.0;

    int ax;

    if (left) {
      // a
      // b c
      ax = x.floor();
    }
    else {
      // _ a
      // b c
      ax = x.ceil();
    }

    int ay = y.floor();
    double aHeight = _get(ax, ay);

    int bx = x.floor();
    int by = y.ceil();
    double bHeight = _get(bx, by);

    int cx = x.ceil();
    int cy = by;
    double cHeight = _get(cx, cy);

    Vector3 ab = new Vector3((ax - bx).toDouble(),
        aHeight - bHeight, (ay - by).toDouble());
    
    Vector3 cb = new Vector3((cx - bx).toDouble(),
        cHeight - bHeight, (cy - by).toDouble());

    Vector3 crossProduct = new Vector3(0.0, 0.0, 0.0);

    cross3(cb, ab, crossProduct);
    crossProduct.normalize();
    return crossProduct;
  }

  double _get(int row, int col) {
    return _bytes[_index(row, col)];
  }

  int _index(int row, int col) {
    if (_size <= row) {
      throw new Exception('row was $row but size is $_size');
    }
    if (_size <= col) {
      throw new Exception('col was $col');
    }

    return _size * row + col;
  }


  Float32List export() {
    List<double> data = [];

    for (int row = 0; row < _size - 1; row++) {

      for (int col = 0; col < _size - 1; col++) {
        // 1  3
        // 2
        // (col, row, _get(col, row)
        // (col, row+1, _get(col, row+1)
        // (col+1, row, _get(col+1, row)

        var vn;

        data.add(col.toDouble());
        data.add(row.toDouble());
        data.add(_get(col, row));
        
        vn = vertexNormal(col, row);
        data.add(vn.x);
        data.add(vn.y);
        data.add(vn.z);

        
        data.add(col.toDouble());
        data.add((row + 1).toDouble());
        data.add(_get(col, row + 1).toDouble());

        vn = vertexNormal(col, row + 1);
        data.add(vn.x);
        data.add(vn.y);
        data.add(vn.z);


        data.add((col + 1).toDouble());
        data.add(row.toDouble());
        data.add(_get(col + 1, row).toDouble());

        vn = vertexNormal(col + 1, row);
        data.add(vn.x);
        data.add(vn.y);
        data.add(vn.z);

        // _ 1
        // 2 3

        // (col+1, row, _get(col+1, row)
        // (col, row+1, _get(col, row+1)
        // (col+1, row+1, _get(col+1, row+1)

        data.add((col + 1).toDouble());
        data.add(row.toDouble());
        data.add(_get(col + 1, row).toDouble());

        vn = vertexNormal(col + 1, row);
        data.add(vn.x);
        data.add(vn.y);
        data.add(vn.z);

        data.add(col.toDouble());
        data.add((row + 1).toDouble());
        data.add(_get(col, row + 1).toDouble());

        vn = vertexNormal(col, row + 1);
        data.add(vn.x);
        data.add(vn.y);
        data.add(vn.z);


        data.add((col + 1).toDouble());
        data.add((row + 1).toDouble());
        data.add(_get(col + 1, row + 1).toDouble());

        vn = vertexNormal(col + 1, row + 1);
        data.add(vn.x);
        data.add(vn.y);
        data.add(vn.z);

        
      }
      
    }

    _theSize = 1024;

   return new Float32List.fromList(data);
  }
}