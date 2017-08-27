import 'dart:async';
import 'dart:html';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

import 'package:rts_demo_client/entity_container.dart';
import 'package:rts_demo_client/renderer.dart';

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
  double _zoomFactor = 20.0;
  int _playerId;
  int _x = 0;
  int _y = 30;
  StreamController _streamController = new StreamController.broadcast();
  // the translation in world units applied when the player's
  // pointer touches the 'bumper'
  int _step = 3;
  Renderer _renderer;
  EntityContainer _entityContainer;

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
      ..onContextMenu.listen(this._handleContextMenu);

    _renderer = new Renderer(_canvas.getContext('webgl'));
  }

  void _onTouchLeftBumper(ev) {
    _x = _x + _step;
  }

  void _onTouchRightBumper(ev) {
    _x = _x - _step;
  }

  int _getEntityAt(Vector2 ndc) {
    for (var entityId in _entityContainer.state['point_masses'].keys) {

      var pointMass = _entityContainer.state['point_masses'][entityId];

      Vector3 entity = new Vector3(
          pointMass['position']['x'],
          0.0,
          pointMass['position']['y']);


      if (_renderer.castRay(ndc, entity)) {
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
      Vector3 pos = _renderer.intersect(ndc);

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
    
    _entityContainer.state['point_masses'].forEach((entityId, pointMass) {
      
      double x = pointMass['position']['x'];
      double y = pointMass['position']['y'];

      Vector3 color;

      if (_entityContainer.state['unit_factories'].containsKey(entityId.toString())) {
        color = new Vector3(1.0, 0.0, 0.0);
      }
      else if (_entityContainer.state['resources'].containsKey(entityId.toString())) {
        color = new Vector3(0.0, 1.0, 0.0);
      }
      else {
        color = new Vector3(0.0, 0.0, 1.0);
      }

      _renderer.render(x, y, color);
      
    });
  }
}
