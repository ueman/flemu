import 'package:gb_emulator/controller/button_listener.dart';

abstract class Controller {
  void setButtonListener(ButtonListener listener);

  //Controller NULL_CONTROLLER = listener -> {};
}
