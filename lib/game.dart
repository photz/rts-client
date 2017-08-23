import 'dart:html';
import 'dart:async';

import 'package:rts_demo_client/map_window.dart';
import 'package:rts_demo_client/control_panel.dart';
import 'package:rts_demo_client/server.dart';
import 'package:rts_demo_client/top_bar.dart';


class Game {
  Element get element => _element;
  
  Server _server;
  Element _element;
  MapWindow _map;
  ControlPanel _controlPanel;
  var _data;
  int _selectedEntity = 0;
  int _playerId = 0;
  StreamSubscription _serverMsgSubscription;
  TopBar _topBar;

  Game(String host, int port) {
    _element = new DivElement()
      ..classes.add('game');

    _server = new Server(host, port);

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

    _map = new MapWindow(_playerId)
      ..events.listen(this._handleMapEvent);

    _controlPanel = new ControlPanel(_playerId)
      ..events.listen(this._handleControlPanelEvents);

    _element.children
      ..add(_topBar.element)
      ..add(_map.element)
      ..add(_controlPanel.element);

    _serverMsgSubscription.onData(this._updateCallback);
  }

  void _updateCallback(data) {
    _data = data;

    try {
      _topBar.funds = _data['players'][_playerId.toString()]['funds'];
    } on NoSuchMethodError catch(e) {}

    _map.rerender(data);
  }

  void _handleControlPanelEvents(ev) {
    _server.send({
      'entity_id' : ev.entityId,
      'msg_type' : 'create_unit'
    });
  }
}
