import 'dart:html';

class TopBar {
  final Element _element = new DivElement();
  final Element _fundsEl = new DivElement();
  Element get element => _element;

  set funds(int value) {
    _fundsEl.innerHtml = value.round().toString() + ' Gold';
  }
  
  TopBar() {
    _element.classes.add('top-bar');
    _fundsEl.classes.add('top-bar__box');
    _element.children.add(_fundsEl);
  }
}
