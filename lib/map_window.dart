import 'dart:async';
import 'dart:html';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

import 'package:rts_demo_client/renderer.dart';

class Unselect {
  Unselect();
}

class EntitySelect {
  int entityId;

  EntitySelect(this.entityId);
}

class SelectPosition {
  double x;
  double y;
  SelectPosition(this.x, this.y);
}

class SelectTarget {
  int entityId;
  SelectTarget(this.entityId);
}

class MapWindow {
  Element get element => _element;
  Element _element;
  Element _leftBumper;
  Element _rightBumper;
  CanvasElement _map;
  double _zoomFactor = 20.0;
  int _playerId;
  int _x = 0;
  int _y = 30;
  StreamController _streamController = new StreamController.broadcast();
  CustomStream get events => _streamController.stream;
  // the translation in world units applied when the player's
  // pointer touches the 'bumper'
  int _step = 3;
  Renderer _renderer;
  var _state = {
    'point_masses' : {},
    'unit_factories' : {},
    'resources' : {}
  };

  MapWindow(int width, int height, this._playerId) {
    _map = new CanvasElement()
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
      ..children.add(_map)
      ..children.add(_leftBumper)
      ..children.add(_rightBumper)
      ..onClick.listen(this._handleClick)
      ..onContextMenu.listen(this._handleContextMenu);

    _renderer = new Renderer(_map.getContext('webgl'));
  }

  void _onTouchLeftBumper(ev) {
    _x = _x + _step;
  }

  void _onTouchRightBumper(ev) {
    _x = _x - _step;
  }

  void _handleContextMenu(ev) {

    // prevent the context menu from showing up
    ev.preventDefault();

    var rec = _map.getBoundingClientRect();
    double x = (ev.client.x / rec.width - 0.5) * 2.0;
    double y = (-1.0) * ((ev.client.y - rec.top) / rec.height - 0.5) * 2.0;    

    Vector2 ndcClick = new Vector2(x, y);

    Vector3 pos = _renderer.intersect(ndcClick);

    _streamController.add(new SelectPosition(pos.x, pos.z));
  }

  void _handleClick(ev) {
    // get position in normalized device coordinates

    var rec = _map.getBoundingClientRect();
    double x = (ev.client.x / rec.width - 0.5) * 2.0;
    double y = (-1.0) * ((ev.client.y - rec.top) / rec.height - 0.5) * 2.0;

    // where the click event occurred in normalized device coordinates
    Vector2 ndcClick = new Vector2(x, y);

    for (var entityId in _state['point_masses'].keys) {

      var pointMass = _state['point_masses'][entityId];

      Vector3 entity = new Vector3(
          pointMass['position']['x'],
          0.0,
          pointMass['position']['y']);


      if (_renderer.castRay(ndcClick, entity)) {
        _streamController.add(new EntitySelect(int.parse(entityId)));
        return;
      }
    }

    _streamController.add(new Unselect());
  }

  void update(state) {
    _state = state;
  }

  void rerender() {

    _renderer.clear();
    
    _state['point_masses'].forEach((entityId, pointMass) {
      
      double x = pointMass['position']['x'];
      double y = pointMass['position']['y'];

      Vector3 color;

      if (_state['unit_factories'].containsKey(entityId.toString())) {
        color = new Vector3(1.0, 0.0, 0.0);
      }
      else if (_state['resources'].containsKey(entityId.toString())) {
        color = new Vector3(0.0, 1.0, 0.0);
      }
      else {
        color = new Vector3(0.0, 0.0, 1.0);
      }

      _renderer.render(x, y, color);
      
    });
  }
}
