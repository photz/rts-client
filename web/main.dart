import 'dart:html';

import 'package:rts_demo_client/game.dart';

void main() {
  var game = new Game();

  var body = querySelector('body');

  body.children.add(game.getElement());
}

