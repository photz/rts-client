import 'dart:async';
import 'dart:html';

class CreateUnit {
  int entityId;
  CreateUnit(this.entityId);
}


class UnitPanel {
  Element get element => _element;
  CustomStream get events => _streamController.stream;

  Element _element;
  var _data;
  int _entityId;
  StreamController _streamController = new StreamController.broadcast();

  UnitPanel(this._entityId, this._data) {
    _element = new DivElement()
      ..classes.add('unit-panel')
      ..classes.add('control-panel__sub-panel')
      ..innerHtml = 'This is a unit. You can order this unit to go somewhere by right-clicking on the map.';
  }
}

class ArmedPanel {
  Element _element;
  Element get element => _element;

  ArmedPanel(int entityId, data) {

    double damage = data['armed'][entityId.toString()]['damage'];

    Element damageEl = new DivElement()
      ..innerHtml = 'Damage: ' + damage.toString();

    double minDist = data['armed'][entityId.toString()]['min_dist'];

    Element minDistEl = new DivElement()
      ..innerHtml = 'Minimum distance: ' + minDist.toString();

    _element = new DivElement()
      ..classes.add('control-panel__sub-panel')
      ..classes.add('armed-panel')
      ..children.add(damageEl)
      ..children.add(minDistEl);
  }
}

class ResourcePanel {
  Element get element => _element;

  Element _element;

  ResourcePanel(int entityId, data) {
    double amount = data['resources'][entityId.toString()]['amount'];

    _element = new DivElement()
      ..classes.add('resource-panel')
      ..classes.add('control-panel__sub-panel')
      ..innerHtml = 'Gold left: ' + amount.toInt().toString();
  }
}

class UnitFactoryPanel {
  Element get element => _element;
  CustomStream get events => _streamController.stream;

  Element _element;
  var _data;
  int _entityId;
  StreamController _streamController = new StreamController.broadcast();

  UnitFactoryPanel(this._entityId, this._data) {

    Element button = new ButtonElement()
      ..innerHtml = 'produce'
      ..onClick.listen(this._handleClick);

    Element queue = new DivElement()
      ..classes.add('unit-factory-panel__queue');


    _element = new DivElement()
      ..classes.add('control-panel__sub-panel')
      ..classes.add('unit-factory-panel')
      ..children.add(queue)
      ..children.add(button);

    int lengthOfQueue = _data['in_queue'];

    for (var i = 0; i < lengthOfQueue; i++) {
      Element unit = new DivElement()
        ..classes.add('unit-factory-panel__unit');

      queue.children.add(unit);
    }
  }

  void _handleClick(ev) {
    _streamController.add(new CreateUnit(_entityId));
  }
}

class HealthPanel {
  Element get element => _element;
  CustomStream get events => _sc.stream;

  Element _element;
  StreamController _sc = new StreamController.broadcast();

  HealthPanel(int entityId, data) {

    double hp = data['health'][entityId.toString()]['hp'];
    double maxHp = data['health'][entityId.toString()]['max_hp'];

    double percentage = 100.0 * hp / maxHp;

    Element healthRemaining = new DivElement()
      ..classes.add('health-panel__health-remaining')
      ..style.width = percentage.toInt().toString() + '%';
    
    Element percentageEl = new DivElement()
      ..classes.add('health-panel__percentage')
      ..innerHtml = percentage.toString() + '%';

    Element healthBar = new DivElement()
      ..classes.add('health-panel__health-bar')
      ..children.add(healthRemaining)
      ..children.add(percentageEl);

    _element = new DivElement()
      ..classes.add('control-panel__sub-panel')
      ..classes.add('health-panel')
      ..children.add(healthBar);
  }
}


class ControlPanel {
  Element get element => _element;
  CustomStream get events => _streamController.stream;

  Element _element;
  var _currentPanel;
  StreamController _streamController = new StreamController.broadcast();
  int _playerId;

  ControlPanel(this._playerId) {
    _element = new DivElement()
      ..classes.add('control-panel');
  }

  void clear() {
    _element.children.clear();
    _currentPanel = null;
  }

  void setSelectedEntity(data, int entityId) {
    clear();

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
