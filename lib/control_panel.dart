import 'dart:async';
import 'dart:html';

class CreateUnit {
  int entityId;
  CreateUnit(this.entityId);
}


abstract class SubPanel {
  
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
}

class ResourcePanel extends SubPanel {
  Element get element => _element;
  CustomStream get events => _streamController.stream;
  
  Element _element;
  StreamController _streamController = new StreamController.broadcast();

  ResourcePanel(playerId, int entityId, data) {
    double amount = data['resources'][entityId.toString()]['amount'];

    _element = new DivElement()
      ..classes.add('resource-panel')
      ..classes.add('control-panel__sub-panel')
      ..innerHtml = 'Gold left: ' + amount.toInt().toString();
  }
}

class UnitFactoryPanel extends SubPanel {
  Element get element => _element;
  CustomStream get events => _streamController.stream;

  final Element _element = new DivElement();
  var _data;
  int _entityId;
  StreamController _streamController = new StreamController.broadcast();

  UnitFactoryPanel(int playerId, this._entityId, this._data) {

    if (!_data.containsKey('ownership') ||
        _data['ownership'][_entityId.toString()] != playerId) {

      return;
    }

    Element button = new ButtonElement()
      ..innerHtml = 'produce'
      ..onClick.listen(this._handleClick);

    Element queue = new DivElement()
      ..classes.add('unit-factory-panel__queue');

    _element
      ..classes.add('control-panel__sub-panel')
      ..classes.add('unit-factory-panel')
      ..children.add(queue)
      ..children.add(button);

    int lengthOfQueue = _data['unit_factories'][_entityId.toString()]['in_queue'];

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

class HealthPanel extends SubPanel {
  Element get element => _element;
  CustomStream get events => _sc.stream;

  Element _element;
  StreamController _sc = new StreamController.broadcast();

  HealthPanel(int playerId, int entityId, data) {

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

  void _handleEvents(ev) {
    _streamController.add(ev);
  }
}
