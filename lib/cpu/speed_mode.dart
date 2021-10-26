import 'package:gb_emulator/address_space.dart';

class SpeedMode implements AddressSpace {
  bool _currentSpeed = false;

  bool _prepareSpeedSwitch = false;

  @override
  bool accepts(int address) => address == 0xff4d;

  @override
  void setByte(int address, int value) {
    _prepareSpeedSwitch = (value & 0x01) != 0;
  }

  @override
  int getByte(int address) {
    return (_currentSpeed ? (1 << 7) : 0) |
        (_prepareSpeedSwitch ? (1 << 0) : 0) |
        126; // 126 == 0b01111110;
  }

  bool onStop() {
    if (_prepareSpeedSwitch) {
      _currentSpeed = !_currentSpeed;
      _prepareSpeedSwitch = false;
      return true;
    } else {
      return false;
    }
  }

  int getSpeedMode() => _currentSpeed ? 2 : 1;
}
