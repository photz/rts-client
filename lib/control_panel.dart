import 'dart:async';
import 'dart:html';

class CreateUnit {
  int entityId;
  CreateUnit(this.entityId);
}


abstract class SubPanel {
  void update(data);
}

class UnitPanel extends SubPanel {
  Element get element => _element;
  CustomStream get events => _streamController.stream;

  final Element _element = new DivElement();
  var _data;
  int _entityId;
  StreamController _streamController = new StreamController.broadcast();

  UnitPanel(playerId, this._entityId, this._data) {
    if (_data.containsKey('ownership') &&
        _data['ownership'][_entityId.toString()] == playerId) {

      _element
        ..classes.add('unit-panel')
        ..classes.add('control-panel__sub-panel')
        ..innerHtml = 'This is a unit. You can order this unit to go somewhere by right-clicking on the map.';
    }
  }
  void update(data) {}
}

class ArmedPanel extends SubPanel {
  CustomStream get events => _streamController.stream;
  Element get element => _element;

  Element _element;
  StreamController _streamController = new StreamController.broadcast();

  ArmedPanel(int playerId, int entityId, data) {

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
  void update(data) {}
}

class ResourcePanel extends SubPanel {
  Element get element => _element;
  CustomStream get events => _streamController.stream;
  
  Element _element;
  StreamController _streamController = new StreamController.broadcast();
  int _entityId;

  ResourcePanel(playerId, this._entityId, data) {
    _element = new DivElement()
      ..classes.add('resource-panel')
      ..classes.add('control-panel__sub-panel');

    update(data);
  }
  void update(data) {
    double amount = data['resources'][_entityId.toString()]['amount'];
    _element.innerHtml = 'Gold left: ' + amount.toInt().toString();
  }
}

class UnitFactoryPanel extends SubPanel {
  Element get element => _element;
  CustomStream get events => _streamController.stream;

  final Element _element = new DivElement();
  int _entityId;
  StreamController _streamController = new StreamController.broadcast();
  Element _queue;
  int _playerId;

  UnitFactoryPanel(this._playerId, this._entityId, data) {

    if (!data.containsKey('ownership') ||
        data['ownership'][_entityId.toString()] != _playerId) {

      return;
    }

    Element button = new ButtonElement()
      ..innerHtml = 'produce'
      ..classes.add('unit-factory-panel__button')
      ..onClick.listen(this._handleClick);

    _queue = new DivElement()
      ..classes.add('unit-factory-panel__queue');

    Element actions = new DivElement()
      ..classes.add('unit-factory-panel__actions')
      ..children.add(button);

    _element
      ..classes.add('control-panel__sub-panel')
      ..classes.add('unit-factory-panel')
      ..children.add(_queue)
      ..children.add(actions);

    update(data);
  }

  void update(data) {
    if (!data.containsKey('ownership') ||
        data['ownership'][_entityId.toString()] != _playerId) {

      return;
    }

    _queue.children.clear();

    int lengthOfQueue = data['unit_factories'][_entityId.toString()]['in_queue'];

    for (var i = 0; i < lengthOfQueue; i++) {
      Element unit = new DivElement()
        ..classes.add('unit-factory-panel__unit');

      _queue.children.add(unit);
    }
  }

  void _handleClick(ev) {
    _streamController.add(new CreateUnit(_entityId));
  }
}

class HealthPanel extends SubPanel {
  Element get element => _element;
  CustomStream get events => _sc.stream;

  Element _element;
  StreamController _sc = new StreamController.broadcast();
  Element _healthRemaining;
  Element _percentageEl;
  int _entityId;

  HealthPanel(int playerId, this._entityId, data) {

    _healthRemaining = new DivElement()
      ..classes.add('health-panel__health-remaining');
    
    _percentageEl = new DivElement()
      ..classes.add('health-panel__percentage');

    Element healthBar = new DivElement()
      ..classes.add('health-panel__health-bar')
      ..children.add(_healthRemaining)
      ..children.add(_percentageEl);

    _element = new DivElement()
      ..classes.add('control-panel__sub-panel')
      ..classes.add('health-panel')
      ..children.add(healthBar);

    update(data);
  }

  void update(data) {
    double hp = data['health'][_entityId.toString()]['hp'];
    double maxHp = data['health'][_entityId.toString()]['max_hp'];

    double percentage = 100.0 * hp / maxHp;

    _healthRemaining.style.width = percentage.toInt().toString() + '%';

    _percentageEl.innerHtml = percentage.toString() + '%';
  }
}


class ControlPanel {
  Element get element => _element;
  CustomStream get events => _streamController.stream;

  static final Map _subPanels = {
    'health' : (pId, eId, d) => new HealthPanel(pId, eId, d),
    'armed' : (pId, eId, d) => new ArmedPanel(pId, eId, d),
    'commands' : (pId, eId, d) => new UnitPanel(pId, eId, d),
    'resources' : (pId, eId, d) => new ResourcePanel(pId, eId, d),
    'unit_factories' : (pId, eId, d) => new UnitFactoryPanel(pId, eId, d)
  };

  Element _element;
  List<SubPanel> _currentSubPanels = [];
  StreamController _streamController = new StreamController.broadcast();
  int _playerId;

  ControlPanel(this._playerId) {
    _element = new DivElement()
      ..classes.add('control-panel');
  }

  void clear() {
    _currentSubPanels.clear();
    _element.children.clear();
  }

  void setSelectedEntity(data, int entityId) {
    clear();

    _subPanels.forEach((componentName, subPanelConstructor) {

      if (!data.containsKey(componentName) ||
          !data[componentName].containsKey(entityId.toString())) {
        return;
      }

      var subPanel = subPanelConstructor(_playerId, entityId, data)
        ..events.listen(this._handleEvents);

      _currentSubPanels.add(subPanel);

      _element.children.add(subPanel.element);

    });
  }

  void update(data) {
    _currentSubPanels.forEach((subPanel) => subPanel.update(data));
  }

  void _handleEvents(ev) {
    _streamController.add(ev);
  }
}
