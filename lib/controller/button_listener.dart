typedef OnButton = void Function(Button b);

class ButtonListener {
  ButtonListener({
    required this.onButtonPress,
    required this.onButtonRelease,
  });

  final OnButton onButtonPress;
  final OnButton onButtonRelease;
}

class Button {
  Button.right()
      : mask = 0x01,
        line = 0x10;

  Button.left()
      : mask = 0x02,
        line = 0x10;

  Button.up()
      : mask = 0x04,
        line = 0x10;

  Button.down()
      : mask = 0x08,
        line = 0x10;

  Button.a()
      : mask = 0x01,
        line = 0x20;

  Button.b()
      : mask = 0x02,
        line = 0x20;

  Button.select()
      : mask = 0x04,
        line = 0x20;

  Button.start()
      : mask = 0x08,
        line = 0x20;

  final int mask;
  final int line;
}
