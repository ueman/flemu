import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/memory/cart/cartridge_type.dart';

class Rom implements AddressSpace {
  final List<int> _rom;

  Rom(this._rom, CartridgeType type, int romBanks, int ramBanks);

  @override
  bool accepts(int address) {
    return (address >= 0x0000 && address < 0x8000) ||
        (address >= 0xa000 && address < 0xc000);
  }

  @override
  void setByte(int address, int value) {}

  @override
  int getByte(int address) {
    if (address >= 0x0000 && address < 0x8000) {
      return _rom[address];
    } else {
      return 0;
    }
  }
}
