import 'dart:async';
import 'dart:html';

class OpenMenu {
  OpenMenu();
}

class TopBar {
  CustomStream get events => _streamController.stream;
  final Element _element = new DivElement();
  final Element _fundsEl = new DivElement();
  Element get element => _element;
  StreamController _streamController = new StreamController.broadcast();

  set funds(int value) {
    _fundsEl.innerHtml = value.round().toString() + ' Gold';
  }
  
  TopBar() {
    Element menuButton = new AnchorElement()
      ..href = '#'
      ..innerHtml = 'Menu'
      ..classes.add('top-bar__menu-button')
      ..onClick.listen(this._onClick);

    _fundsEl.classes.add('top-bar__box');

    _element
      ..classes.add('top-bar')
      ..children.add(_fundsEl)
      ..children.add(menuButton);
  }

  void _onClick(ev) {
    _streamController.add(new OpenMenu());
  }
}
