import 'dart:math' as math;

class EntityContainer {
  get state => _entities;
  num _lastUpdate = 0;
  var _entities = {
    'point_masses' : {}
  };

  EntityStore() {
    
  }

  void update(entities) {
    _entities = entities;
  }

  void tick(num now) {
    // ms
    num elapsed = now - _lastUpdate;

    _movement(elapsed);
    _lastUpdate = now;
  }

  void _movement(num time) {
    if (!_entities.containsKey('point_masses')) {
      return;
    }

    _entities['point_masses'].forEach((entityId, pointMass) {

      double x = pointMass['position']['x'];
      double y = pointMass['position']['y'];

      double xVel = pointMass['velocity']['x'];
      double yVel = pointMass['velocity']['y'];

      double xd = xVel * time / 1000.0; 
      double yd = yVel * time / 1000.0;

      _entities['point_masses'][entityId]['position']['x'] += xd;
      _entities['point_masses'][entityId]['position']['y'] += yd;

    });
  }
}