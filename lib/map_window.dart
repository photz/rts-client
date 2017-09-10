import 'dart:async';
import 'dart:html';
import 'dart:web_gl';
import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

import 'package:rts_demo_client/entity_container.dart';
import 'package:rts_demo_client/renderer.dart';
import 'package:rts_demo_client/mesh.dart';
import 'package:rts_demo_client/model.dart';
import 'package:rts_demo_client/terrainrenderer.dart';
import 'package:rts_demo_client/heightmap.dart';

class MapWindowEvent {
  
}

class Unselect extends MapWindowEvent {
  Unselect();
}

class EntitySelect extends MapWindowEvent {
  int entityId;

  EntitySelect(this.entityId);
}

class SelectPosition extends MapWindowEvent {
  double x;
  double y;
  SelectPosition(this.x, this.y);
}

class SelectTarget extends MapWindowEvent {
  int entityId;
  SelectTarget(this.entityId);
}



class MapWindow {
  Element get element => _element;
  CustomStream get events => _streamController.stream;

  Element _element;
  Element _leftBumper;
  Element _rightBumper;
  CanvasElement _canvas;
  int _playerId;
  StreamController _streamController = new StreamController.broadcast();
  // the translation in world units applied when the player's
  // pointer touches the 'bumper'
  int _step = 3;
  Renderer _renderer;
  EntityContainer _entityContainer;
  Mesh _tankMesh;
  Mesh _baseMesh;
  Mesh _mineMesh;
  Vector3 _camera = new Vector3(30.0, 30.0, 30.0);
  TerrainRenderer _terrainRenderer;
  Heightmap _heightmap;

  MapWindow(int width, int height, this._playerId, this._entityContainer) {
    _canvas = new CanvasElement()
      ..width = width
      ..height = height
      ..classes.add('map-window__map');

    _leftBumper = new DivElement()
      ..classes.add('map-window__bumper')
      ..classes.add('map-window__bumper--left')
      ..onMouseOver.listen(this._onTouchLeftBumper);

    _rightBumper = new DivElement()
      ..classes.add('map-window__bumper')
      ..classes.add('map-window__bumper--right')
      ..onMouseOver.listen(this._onTouchRightBumper);

    _element = new DivElement()
      ..classes.add('map-window')
      ..children.add(_canvas)
      ..children.add(_leftBumper)
      ..children.add(_rightBumper)
      ..onClick.listen(this._handleClick)
      ..onContextMenu.listen(this._handleContextMenu)
      ..onMouseWheel.listen(this._onMouseWheel);

    RenderingContext gl = _canvas.getContext('webgl');

    var rng = new math.Random();
    List heightmapData = [];

    for (int row = 0; row < 32; row++) {

      for (int col = 0; col < 32; col++) {
        if (row == 0) {
          heightmapData.add(2.0);
        }
        else if (row == 1) {
          heightmapData.add(1.0);
        }
        else {
          heightmapData.add(0.0);//rng.nextDouble() * 3.0 - 1.0);
        }
      }
    }

    heightmapData[0] = 5.0;

    _heightmap = new Heightmap(heightmapData);

    _terrainRenderer = new TerrainRenderer(gl, _heightmap);

    _mineMesh = new Mesh(gl, new Model.fromObj(myLoadModel('thing.obj')));

    Model model = new Model.fromObj(myLoadModel('minitank.obj'));
    _tankMesh = new Mesh(gl, model);

    Model baseModel = new Model.fromObj(myLoadModel('base.obj'));
    _baseMesh = new Mesh(gl, baseModel);

    _renderer = new Renderer(gl);
  }

  void _onMouseWheel(ev) {
    int delta = ev.deltaY;
    _camera.addScaled(new Vector3(1.0, 1.0, 1.0),
        delta / 50.0);
  }

  void _onTouchLeftBumper(ev) {
  }

  void _onTouchRightBumper(ev) {
  }

  int _getEntityAt(Vector2 ndc) {
    for (var entityId in _entityContainer.state['point_masses'].keys) {

      var pointMass = _entityContainer.state['point_masses'][entityId];

      Vector3 entity = new Vector3(
          pointMass['position']['x'],
          0.0,
          pointMass['position']['y']);


      if (_castRay(ndc, entity)) {
        return int.parse(entityId);
      }
    }
    return 0;
  }

  Vector2 _ndcFromMouseEvent(MouseEvent ev) {
    var rec = _canvas.getBoundingClientRect();
    double x = (ev.client.x / rec.width - 0.5) * 2.0;
    double y = (-1.0) * ((ev.client.y - rec.top) / rec.height - 0.5) * 2.0;    

    return new Vector2(x, y);
  }
 
  void _handleContextMenu(ev) {
    // prevent the context menu from showing up
    ev.preventDefault();

    Vector2 ndc = _ndcFromMouseEvent(ev);
    
    int entityId = _getEntityAt(ndc);

    if (0 < entityId) {
      _streamController.add(new SelectTarget(entityId));
    }
    else {
      Vector3 pos = _intersect(ndc);

      _streamController.add(new SelectPosition(pos.x, pos.z));
    }
  }

  void _handleClick(ev) {
    Vector2 ndc = _ndcFromMouseEvent(ev);

    int entityId = _getEntityAt(ndc);

    if (0 < entityId) {
      _streamController.add(new EntitySelect(entityId));
    }
    else {
      _streamController.add(new Unselect());
    }
  }

  void redraw(time) {

    _renderer.clear();
    
    _terrainRenderer.render(_getProjectionMatrix(), _getViewMatrix());

    _entityContainer.state['point_masses'].forEach((entityId, pointMass) {
      
      double x = pointMass['position']['x'];
      double y = pointMass['position']['y'];
      double yaw = pointMass['orientation'];

      // u_ModelMatrix
      Matrix4 modelMatrix = new Matrix4.translation(new Vector3(x, 0.0, y));
      //modelMatrix.rotateY(yaw * degrees2Radians);

      if (0.0 < x && 0.0 < y) {
        Vector3 fwd = new Vector3(math.cos(yaw * degrees2Radians), 0.0, math.sin(yaw * degrees2Radians));
        fwd.normalize();
        Vector3 normal = _heightmap.normal(x, y);
        double height = _heightmap.height(x, y);
        normal.normalize();
        Vector3 right = new Vector3.zero();
        right.normalize();
        cross3(normal, fwd, right);
        cross3(right, normal, fwd);

        modelMatrix.translate(new Vector3(0.0, height, 0.0));
    
        // convert to Vector4

        Vector4 fwd4 = new Vector4(fwd.x, fwd.y, fwd.z, 0.0);
        Vector4 normal4 = new Vector4(normal.x, normal.y, normal.z, 0.0);
        Vector4 right4 = new Vector4(right.x, right.y, right.z, 0.0);
        fwd4.normalize();
        normal4.normalize();
        right4.normalize();

        Matrix4 rot = new Matrix4.columns(right4, normal4, fwd4, new Vector4(0.0, 0.0, 0.0, 1.0));
        print(normal);

        //rot.transpose();
        modelMatrix.multiply(rot);
      }


      Vector3 color;
      Mesh mesh;

      if (_entityContainer.state['unit_factories'].containsKey(entityId.toString())) {
        color = new Vector3(1.0, 0.0, 0.0);
        mesh = _baseMesh;
      }
      else if (_entityContainer.state['resources'].containsKey(entityId.toString())) {
        color = new Vector3(0.0, 1.0, 0.0);
        mesh = _mineMesh;
      }
      else if (_entityContainer.state['commands'].containsKey(entityId.toString())) {
        color = new Vector3(0.0, 1.0, 0.0);
        mesh = _tankMesh;
      }
      else {
        color = new Vector3(0.0, 0.0, 1.0);
      }

      _renderer.render(_getProjectionMatrix(), _getViewMatrix(), modelMatrix, yaw, color, mesh);
      
    });
  }



  Matrix4 _getViewMatrix() {
    return makeViewMatrix(_camera,
        _getLookAt(),
        new Vector3(0.0, 1.0, 0.0));
        
  }

  Vector3 _getLookAt() {
    return new Vector3(0.0, 0.0, 0.0);
  }


  Vector3 ndcToWorld(Vector2 ndc) {
    var m = _getProjectionMatrix() * _getViewMatrix();
    m.invert();

    return (m * ndc).xyz;
  }

  Vector3 _intersect(Vector2 ndc) {

    Vector3 view = _getLookAt() - _camera;
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

    Vector3 pos = _camera + view + h.scaled(ndc.x) + v.scaled(ndc.y);

    Vector3 direction = pos - _camera;

    direction.normalize();


    double s = - _camera.y / direction.y;

    Vector3 where = _camera + direction.scaled(s);

    return where;
  }

  bool _castRay(Vector2 ndc, Vector3 entity) {
    Vector3 view = _getLookAt() - _camera;
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

    Vector3 pos = _camera + view + h.scaled(ndc.x) + v.scaled(ndc.y);

    Vector3 direction = pos - _camera;

    direction.normalize();


    Vector3 l = entity - _camera;

    double tca = dot3(l, direction);

    double d = math.sqrt(math.pow(l.length, 2) - math.pow(tca, 2));

    return d < 1.0;
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
}
