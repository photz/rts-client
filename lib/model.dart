import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

class Vertex {
  final Model _model;
  final int _vertexIndex;
  final int _normalIndex;

  Vector3 get position => _model.positions[_vertexIndex];
  Vector3 get normal => _model.normals[_normalIndex];
  int get vertexIndex => _vertexIndex;
  int get normalIndex => _normalIndex;

  Vertex(this._model, this._vertexIndex, this._normalIndex) {
    if (_model.positions.length <= vertexIndex) {
      throw new Exception('index too high');
    }
  }
}

class Triangle {
  final List<Vertex> _vertices;

  List<Vertex> get vertices => _vertices;

  Triangle(this._vertices) {
    if (_vertices.length != 3) {
      throw new Exception("only triangular faces are supported");
    }

    if (null == _vertices) {
      throw new Exception('no vertices provided');
    }
  }

  String toString() {
    return this._vertices
      .map((v) => (v.vertexIndex + 1).toString() + '//' + (v.normalIndex + 1).toString())
      .join(' ');
  }
}

class Model {
  List<Vector3> _positions;
  List<Triangle> _triangles;
  List<Vector3> _normals;

  List<Vector3> get positions => _positions;
  List<Vector3> get normals => _normals;
  List<Triangle> get triangles => _triangles;

  Model.fromObj(String objFile) {

    List<String> lines = objFile.split("\n");

    this._positions = new List.from(lines.where(_isVertexDef).map(_vertexDefToVertex));
    this._normals = new List.from(lines.where(_isNormalDef).map(_normalDefToNormal));
    this._triangles = new List.from(lines.where(_isFaceDef).map(this._faceDefToFace));
  }

  static bool _isVertexDef(String line) {
    return line.startsWith("v ");
  }

  static bool _isNormalDef(String line) {
    return line.startsWith("vn ");
  }

  static bool _isFaceDef(String line) {
    return line.startsWith("f ");
  }

  static Vector3 _vertexDefToVertex(String vertexDef) {
    RegExp e = new RegExp(r" +");
    List<double> components = new List.from(vertexDef.split(e).skip(1).map(double.parse));

    return new Vector3.array(components);
  }

  static Vector3 _normalDefToNormal(String normalDef) {
    RegExp e = new RegExp(r" +");
    List<double> components = new List.from(normalDef.split(e).skip(1).map(double.parse));

    return new Vector3.array(components);
  }

  Triangle _faceDefToFace(String faceDef) {
    RegExp e = new RegExp(r" +");

    List<Vertex> vertices = new List.from(faceDef.trim().split(e).skip(1)
        .map(this._vertexDefToVertex2));

    Triangle triangle = new Triangle(vertices);

    return triangle;
  }

  Vertex _vertexDefToVertex2(String vertexDef) {
    List<String> constituents = vertexDef.split("//");

    int vertexIndex = int.parse(constituents.first) - 1;
    int normalIndex = int.parse(constituents.last) - 1;

    Vertex vertex = new Vertex(this, vertexIndex, normalIndex);

    return vertex;
  }

  // constraint:
  // for all vertices v, u
  // such that v and u have the same index in the index buffer
  // v and u also have the same position and the same normal

  Float32List positionsAndNormalsToArr() {
    const int floatsPerVector = 3;

    // two vectors for the position and the normal
    const int floatsPerVertex = floatsPerVector * 2;
    
    const int floatsPerTriangle = 3 * floatsPerVertex;

    final int elements = floatsPerTriangle * _triangles.length;
    final Float32List list = new Float32List(elements);

    _triangles.asMap().forEach((triangleIndex, triangle) {

      int triangleOffset = triangleIndex * floatsPerTriangle;

      triangle.vertices.asMap().forEach((vertexIndex, vertex) {

        int offset = triangleOffset + vertexIndex * floatsPerVertex;

        vertex.position.copyIntoArray(list, offset);

        vertex.normal.copyIntoArray(list, offset + floatsPerVector);
      });
    });

    return list;
  }
}

