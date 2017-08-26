import 'dart:html';

class MainMenu {
  Element get element => _element;

  final Element _element = new DivElement();

  MainMenu() {
    Element settings = new ButtonElement()
      ..classes.add('main-menu__item')
      ..innerHtml = 'Settings';

    Element players = new ButtonElement()
      ..classes.add('main-menu__item')
      ..innerHtml = 'Players';
      
    Element about = new ButtonElement()
      ..classes.add('main-menu__item')
      ..innerHtml = 'About';

    _element
      ..classes.add('main-menu')
      ..children.add(settings)
      ..children.add(players)
      ..children.add(about);
  }
}