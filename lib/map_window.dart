import 'dart:async';
import 'dart:html';
import 'dart:web_gl';

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
  Element _map;
  double _zoomFactor = 20.0;
  int _playerId;
  int _x = 0;
  int _y = 30;
  StreamController _streamController = new StreamController.broadcast();
  CustomStream get events => _streamController.stream;
  // the translation in world units applied when the player's
  // pointer touches the 'bumper'
  int _step = 3;
  RenderingContext _gl;

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

    _gl = new RenderingContext(_map.getContext('webgl'))
      ..clearColor(0.0, 0.0, 0.0, 0.0)
      ..enable(DEPTH_TEST);
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
  }

  void _handleClick(ev) {
  }

  void rerender(state) {
    _gl.clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT);

    state['point_masses'].forEach((entityId, pointMass) {
      
      
    });
  }
}
