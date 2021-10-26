import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/memory/cart/battery/battery.dart';
import 'package:gb_emulator/memory/cart/cartridge_type.dart';

class Mbc2 implements AddressSpace {
  final CartridgeType _type;

  final int _romBanks;

  final List<int> _cartridge;

  late final List<int> _ram;

  final Battery _battery;

  int _selectedRomBank = 1;

  bool _ramWriteEnabled = false;

  Mbc2(this._cartridge, this._type, this._battery, this._romBanks) {
    _ram = []; //new int[0x0200];
    for (int i = 0; i < 0x0200; i++) {
      _ram[i] = 0xff;
    }
    _battery.loadRam(_ram);
  }

  @override
  bool accepts(int address) {
    return (address >= 0x0000 && address < 0x8000) ||
        (address >= 0xa000 && address < 0xc000);
  }

  @override
  void setByte(int address, int value) {
    if (address >= 0x0000 && address < 0x2000) {
      if ((address & 0x0100) == 0) {
        _ramWriteEnabled = (value & 10 /* 0b1010 */) != 0;
        if (!_ramWriteEnabled) {
          _battery.saveRam(_ram);
        }
      }
    } else if (address >= 0x2000 && address < 0x4000) {
      if ((address & 0x0100) != 0) {
        _selectedRomBank = value & 15; //0b00001111;
      }
    } else if (address >= 0xa000 && address < 0xc000 && _ramWriteEnabled) {
      int ramAddress = _getRamAddress(address);
      if (ramAddress < _ram.length) {
        _ram[ramAddress] = value & 0x0f;
      }
    }
  }

  @override
  int getByte(int address) {
    if (address >= 0x0000 && address < 0x4000) {
      return _getRomByte(0, address);
    } else if (address >= 0x4000 && address < 0x8000) {
      return _getRomByte(_selectedRomBank, address - 0x4000);
    } else if (address >= 0xa000 && address < 0xb000) {
      int ramAddress = _getRamAddress(address);
      if (ramAddress < _ram.length) {
        return _ram[ramAddress];
      } else {
        return 0xff;
      }
    } else {
      return 0xff;
    }
  }

  int _getRomByte(int bank, int address) {
    int cartOffset = bank * 0x4000 + address;
    if (cartOffset < _cartridge.length) {
      return _cartridge[cartOffset];
    } else {
      return 0xff;
    }
  }

  int _getRamAddress(int address) {
    return address - 0xa000;
  }
}
