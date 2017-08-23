import 'dart:async';
import 'dart:html';

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
  double _zoomFactor = 10.0;
  int _playerId;
  int _x = 0;
  int _y = 30;
  StreamController _streamController = new StreamController.broadcast();
  CustomStream get events => _streamController.stream;
  // the translation in world units applied when the player's
  // pointer touches the 'bumper'
  int _step = 3;

  MapWindow(this._playerId) {
    _map = new DivElement()
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
  }

  void _onTouchLeftBumper(ev) {
    _x = _x + _step;
  }

  void _onTouchRightBumper(ev) {
    _x = _x - _step;
  }

  void _handleContextMenu(ev) {
    if (ev.target.classes.contains('map-window__entity')) {
      int entityId = int.parse(ev.target.dataset['entity-id']);
      var selectTargetEvent = new SelectTarget(entityId);
      _streamController.add(selectTargetEvent);
    }
    else {
      // determine coordinates relative to the map
      _map.style.display = '';
      var rec = _map.getBoundingClientRect();
      double x = ev.client.x / _zoomFactor - _x;
      double y = -(ev.client.y - rec.top) / _zoomFactor + _y;

      var newEv = new SelectPosition(x, y);
      _streamController.add(newEv);
    }

    // prevent the context menu from showing up
    ev.preventDefault();
  }

  void _handleClick(ev) {
    if (ev.target.classes.contains('map-window__entity')) {
      int entityId = int.parse(ev.target.dataset['entityId']);

      _streamController.add(new EntitySelect(entityId));      
    }
    else {
      _streamController.add(new Unselect());
    }
  }

  void rerender(state) {
    _map.children.clear();

    state['point_masses'].forEach((entityId, pointMass) {
      Element entityEl = new DivElement();

      entityEl.classes.add('map-window__entity');

      entityEl.dataset['entityId'] = entityId.toString();

      if (state.containsKey('resources') &&
          state['resources'].containsKey(entityId)) {
        entityEl.classes.add('map-window__entity--gold-mine');
      }

      if (state.containsKey('commands') &&
          state['commands'].containsKey(entityId)) {
        entityEl.classes.add('map-window__entity--unit');
      }

      if (state.containsKey('unit_factories') &&
          state['unit_factories'].containsKey(entityId)) {
        entityEl.classes.add('map-window__entity--unit-factory');
      }

      if (state.containsKey('ownership') &&
          state['ownership'].containsKey(entityId.toString())) {
        int ownerId = state['ownership'][entityId.toString()];

        if (ownerId == _playerId) {
          entityEl.classes.add('map-window__entity--friendly');
        }
      }
      
      var xWorld = pointMass['position']['x'];
      var yWorld = pointMass['position']['y'];

      var xScreen = (xWorld + _x) * _zoomFactor;
      var yScreen = (_y - yWorld) * _zoomFactor;

      entityEl.style.transform = 'translate3d(${xScreen}px,${yScreen}px,0)';

      _map.children.add(entityEl);
    });
  }
}
