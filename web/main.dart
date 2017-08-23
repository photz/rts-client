import 'dart:html';

import 'package:rts_demo_client/game.dart';

void main() {
  int port = const int.fromEnvironment('port');
  String host = const String.fromEnvironment('host');

  var game = new Game(host, port);

  var body = querySelector('body');

  body.children.add(game.element);
}

