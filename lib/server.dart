import 'dart:async';
import 'dart:html';
import 'dart:convert';

class Server {
  WebSocket _ws;
  StreamController _streamController = new StreamController.broadcast();

  CustomStream get events => _streamController.stream;

  Server(String host, int port) {
    _ws = new WebSocket(host + ':' + port.toString());
    _ws.onOpen.listen(this._onOpen);
    _ws.onError.listen(this._onError);
  }

  void _onOpen(Event e) {
    _ws.onMessage.listen(this._onMessage);
    print('opened');
  }

  void _onError(ev) {
    print('error occurred');
  }

  void _onMessage(MessageEvent e) {
    var data = JSON.decode(e.data);
    _streamController.add(data);
  }

  void send(x) {
    String json = JSON.encode(x);
    _ws.sendString(json);
  }
}
