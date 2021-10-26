import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/memory/ram.dart';

class UndocumentedGbcRegisters implements AddressSpace {
  final Ram _ram = Ram(0xff72, 6);
  int _xff6c = 0xfe;

  UndocumentedGbcRegisters() {
    _ram.setByte(0xff74, 0xff);
    _ram.setByte(0xff75, 0x8f);
  }

  @override
  bool accepts(int address) {
    return address == 0xff6c || _ram.accepts(address);
  }

  @override
  void setByte(int address, int value) {
    switch (address) {
      case 0xff6c:
        _xff6c = 0xfe | (value & 1);
        break;

      case 0xff72:
      case 0xff73:
      case 0xff74:
        _ram.setByte(address, value);
        break;

      case 0xff75:
        _ram.setByte(address, 0x8f | (value & 112 /* 0b01110000 */));
    }
  }

  @override
  int getByte(int address) {
    if (address == 0xff6c) {
      return _xff6c;
    } else if (_ram.accepts(address)) {
      return _ram.getByte(address);
    } else {
      throw Exception('IllegalArgument');
    }
  }
}
