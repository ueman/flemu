import 'package:gb_emulator/address_space.dart';

class GbcRam implements AddressSpace {
  List<int> ram = [];
  final ramLength = 7 * 0x1000;

  int _svbk = 0;

  @override
  bool accepts(int address) {
    return address == 0xff70 || (address >= 0xd000 && address < 0xe000);
  }

  @override
  void setByte(int address, int value) {
    if (address == 0xff70) {
      _svbk = value;
    } else {
      ram[_translate(address)] = value;
    }
  }

  @override
  int getByte(int address) {
    if (address == 0xff70) {
      return _svbk;
    } else {
      return ram[_translate(address)];
    }
  }

  int _translate(int address) {
    int ramBank = _svbk & 0x7;
    if (ramBank == 0) {
      ramBank = 1;
    }
    int result = address - 0xd000 + (ramBank - 1) * 0x1000;
    if (result < 0 || result >= ramLength) {
      throw Exception();
    }
    return result;
  }
}
