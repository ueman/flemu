import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/controller/button_listener.dart';
import 'package:gb_emulator/controller/controller.dart';
import 'package:gb_emulator/cpu/interrupt_manager.dart';

class Joypad implements AddressSpace {
  Set<Button> _buttons = {};

  int _p1 = 0;

  Joypad(InterruptManager interruptManager, Controller controller) {
    controller.setButtonListener(
      ButtonListener(
        onButtonPress: (button) {
          interruptManager.requestInterrupt(const InterruptType.p10_13());
          _buttons.add(button);
        },
        onButtonRelease: (button) {
          _buttons.remove(button);
        },
      ),
    );
  }

  @override
  bool accepts(int address) {
    return address == 0xff00;
  }

  @override
  void setByte(int address, int value) {
    _p1 = value & 48; // 0b00110000
  }

  @override
  int getByte(int address) {
    int result = _p1 | 207; // 0b11001111
    for (final b in _buttons) {
      if ((b.line & _p1) == 0) {
        result &= 0xff & ~b.mask;
      }
    }
    return result;
  }
}
