import 'dart:html';
import 'dart:async';

import 'package:rts_demo_client/server.dart';

class Coord {
  double x;
  double y;
  
  Coord(this.x, this.y);
}

class EntitySelect {
  int entityId;

  EntitySelect(this.entityId);
}

class CreateUnit {
  int entityId;
  CreateUnit(this.entityId);
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
  double _zoomFactor = 30.0;
  Element _element;
  int _playerId;

  Element get element => _element;

  Element _map;

  StreamController _streamController = new StreamController.broadcast();

  CustomStream get events => _streamController.stream;

  MapWindow(this._playerId) {
    _element = new DivElement();
    _element.classes.add('map-window');
    _map = new DivElement();
    _map.classes.add('map-window__map');
    _map.style.top = '600px';
    _element.children.add(_map);
    _element.onClick.listen(this._handleClick);
    _element.onContextMenu.listen(this._handleContextMenu);
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
      double x = (ev.client.x + rec.left) / _zoomFactor;
      double y = -(ev.client.y - rec.top) / _zoomFactor;

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
  }

  void rerender(state) {
    _map.children.clear();

    state['point_masses'].forEach((entityId, pointMass) {
      Element entityEl = new DivElement();

      entityEl.classes.add('map-window__entity');

      entityEl.dataset['entityId'] = entityId.toString();

      var x = pointMass['position']['x'];
      var y = pointMass['position']['y'];


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



      entityEl.style.top = (((-1) * y * _zoomFactor)).toString() + 'px';
      entityEl.style.left = (_zoomFactor * x).toString() + 'px';

      _map.children.add(entityEl);
    });
  }
}

class UnitPanel {
  Element _element;
  var _data;
  int _entityId;

  Element get element => _element;

  StreamController _streamController = new StreamController.broadcast();
  CustomStream get events => _streamController.stream;

  UnitPanel(this._entityId, this._data) {
    _element = new DivElement();
    _element.classes.add('unit-panel');
    _element.innerHtml = 'This is a unit. You can order this unit to go somewhere by right-clicking on the map.';
    _element.onClick.listen(this._handleClick);
  }

  void _handleClick(ev) {
    
  }
}

class ArmedPanel {
  Element _element;
  Element get element => _element;
  ArmedPanel(int entityId, data) {
    _element = new DivElement();
    _element.classes.add('control-panel__sub-panel');
    _element.classes.add('armed-panel');

    double damage = data['armed'][entityId.toString()]['damage'];
    Element damageEl = new DivElement();
    damageEl.innerHtml = 'Damage: ' + damage.toString();
    _element.children.add(damageEl);

    double minDist = data['armed'][entityId.toString()]['min_dist'];
    Element minDistEl = new DivElement();
    minDistEl.innerHtml = 'Minimum distance: ' + minDist.toString();
    _element.children.add(minDistEl);
  }
}

class ResourcePanel {
  Element _element;
  Element get element => _element;
  ResourcePanel(int entityId, data) {
    _element = new DivElement();
    _element.classes.add('resource-panel');
    double amount = data['resources'][entityId.toString()]['amount'];
    _element.innerHtml = 'Gold left: ' + amount.toInt().toString();
  }
}

class UnitFactoryPanel {
  Element _element;
  var _data;
  int _entityId;

  Element get element => _element;

  StreamController _streamController = new StreamController.broadcast();

  CustomStream get events => _streamController.stream;

  UnitFactoryPanel(this._entityId, this._data) {
    _element = new DivElement();
    _element.classes.add('control-panel__sub-panel');
    _element.classes.add('unit-factory-panel');
    _element.innerHtml = 'length of queue: ' + _data['in_queue'].toString();
    Element button = new ButtonElement();
    button.innerHtml = 'produce';
    _element.children.add(button);
    button.onClick.listen(this._handleClick);
  }

  void _handleClick(ev) {
    _streamController.add(new CreateUnit(_entityId));
  }
}

class HealthPanel {
  Element _element;
  Element get element => _element;
  StreamController _sc = new StreamController.broadcast();
  CustomStream get events => _sc.stream;
  HealthPanel(int entityId, data) {
    _element = new DivElement();
    _element.classes.add('control-panel__sub-panel');    
    _element.classes.add('health-panel');
    double hp = data['health'][entityId.toString()]['hp'];
    double maxHp = data['health'][entityId.toString()]['max_hp'];

    Element healthBar = new DivElement();
    healthBar.classes.add('health-panel__health-bar');
    _element.children.add(healthBar);

    Element healthRemaining = new DivElement();
    healthRemaining.classes.add('health-panel__health-remaining');
    healthBar.children.add(healthRemaining);

    double percentage = 100.0 * hp / maxHp;
    healthRemaining.style.width = percentage.toInt().toString() + '%';
    
    Element percentageEl = new DivElement();
    percentageEl.classes.add('health-panel__percentage');
    percentageEl.innerHtml = percentage.toString() + '%';
    healthBar.children.add(percentageEl);
  }
}


class ControlPanel {
  Element _element;
  var _currentPanel;
  StreamController _streamController = new StreamController.broadcast();
  int _playerId;

  Element get element => _element;
  CustomStream get events => _streamController.stream;

  ControlPanel(this._playerId) {
    _element = new DivElement();
    _element.classes.add('control-panel');
  }

  void setSelectedEntity(data, int entityId) {
    _element.children.clear();
    _currentPanel = null;


    bool friendly = false;

    if (data.containsKey('ownership') &&
        data['ownership'].containsKey(entityId.toString())) {
        
      friendly = data['ownership'][entityId.toString()] == _playerId;
    }

    if (friendly && data.containsKey('commands') &&
        data['commands'].containsKey(entityId.toString())) {

      _currentPanel = new UnitPanel(entityId, data['commands'][entityId.toString()]);
      _element.children.add(_currentPanel.element);
      _currentPanel.events.listen(this._handleEvents);

    }

    if (friendly && data.containsKey('unit_factories') &&
        data['unit_factories'].containsKey(entityId.toString())) {

      _currentPanel = new UnitFactoryPanel(entityId, data['unit_factories'][entityId.toString()]);
      _element.children.add(_currentPanel.element);
      _currentPanel.events.listen(this._handleEvents);
    }

    if (data.containsKey('armed') &&
        data['armed'].containsKey(entityId.toString())) {
      var armedPanel = new ArmedPanel(entityId, data);
      _element.children.add(armedPanel.element);
    }

    if (data.containsKey('health') &&
        data['health'].containsKey(entityId.toString())) {

      var healthPanel = new HealthPanel(entityId, data);
      _element.children.add(healthPanel.element);

    }

    if (data.containsKey('resources') &&
        data['resources'].containsKey(entityId.toString())) {

      var resourcePanel = new ResourcePanel(entityId, data);
      _element.children.add(resourcePanel.element);
    }
  }

  void _handleEvents(ev) {
    _streamController.add(ev);
  }
}

class TopBar {
  final Element _element = new DivElement();
  final Element _fundsEl = new DivElement();
  Element get element => _element;

  set funds(int value) {
    _fundsEl.innerHtml = value.round().toString() + ' Gold';
  }
  
  TopBar() {
    _element.classes.add('top-bar');
    _fundsEl.classes.add('top-bar__funds');
    _element.children.add(_fundsEl);
  }
}

class Game {
  Server _server;
  Element _element;
  MapWindow _map;
  ControlPanel _controlPanel;
  var _data;
  int _selectedEntity = 0;
  int _playerId = 0;
  StreamSubscription _serverMsgSubscription;
  TopBar _topBar;

  Game() {
    _element = new DivElement();
    _element.classes.add('game');
    _server = new Server('ws://127.0.0.1', 9004);
    _serverMsgSubscription = _server.events.listen(this._handleInitialMessage);

  }

  void _handleMapEvent(ev) {
    if (ev is EntitySelect) {
      _controlPanel.setSelectedEntity(_data, ev.entityId);
      _selectedEntity = ev.entityId;
    }
    else if (ev is SelectTarget) {

      if (_data.containsKey('commands') &&
          _data['commands'].containsKey(_selectedEntity.toString())) {
        _server.send({
          'entity_id' : _selectedEntity,
          'msg_type' : 'unit_attack',
          'target' : ev.entityId
        });
      }
      else {
        print('invalid attack command');
      }
    }
    else if (ev is SelectPosition) {
      _server.send({
        'entity_id' : _selectedEntity,
        'msg_type' : 'unit_go_to',
        'dest' : {
          'x' : ev.x,
          'y' : ev.y
        }
      });
    }
  }

  void _handleInitialMessage(data) {
    _playerId = data['player_id'];

    _topBar = new TopBar();
    _element.children.add(_topBar.element);
    _map = new MapWindow(_playerId);
    _map.events.listen(this._handleMapEvent);
    _controlPanel = new ControlPanel(_playerId);
    _controlPanel.events.listen(this._handleControlPanelEvents);
    _element.children.add(_map.element);
    _element.children.add(_controlPanel.element);
    _serverMsgSubscription.onData(this._updateCallback);
  }

  void _updateCallback(data) {
    _data = data;

    try {
      _topBar.funds = _data['players'][_playerId.toString()]['funds'];
    } on NoSuchMethodError catch(e) {}

    _map.rerender(data);
  }

  Element getElement() {
    return _element;
  }

  void _handleControlPanelEvents(ev) {
    _server.send({
      'entity_id' : ev.entityId,
      'msg_type' : 'create_unit'
    });
  }
}
