class EntityContainer {
  get state => _entities;
  var _lastUpdate = 0;
  var _entities = {
    'point_masses' : {}
  };

  EntityStore() {

  }

  void update(entities) {
    _entities = entities;
  }

  void tick(time) {
    _lastUpdate = (new DateTime.now()).millisecondsSinceEpoch;
    _movement(time);
  }

  void _movement(time) {
    if (!_entities.containsKey('point_masses')) {
      return;
    }

    _entities['point_masses'].forEach((entityId, pointMass) {

      double x = pointMass['position']['x'];
      double y = pointMass['position']['y'];

      double xVel = pointMass['velocity']['x'];
      double yVel = pointMass['velocity']['y'];

      double xd = xVel * time / 1000000.0; 
      double yd = yVel * time / 1000000.0;

      _entities['point_masses'][entityId]['position']['x'] += xd;
      _entities['point_masses'][entityId]['position']['y'] += yd;

    });
  }
}