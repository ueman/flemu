import 'dart:math';

import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/int_x.dart';
import 'package:gb_emulator/memory/cart/battery/battery.dart';
import 'package:gb_emulator/memory/cart/cartridge_type.dart';

class Mbc5 implements AddressSpace {
  final CartridgeType _type;

  final int _romBanks;

  final int _ramBanks;

  final List<int> _cartridge;

  late final List<int> _ram;

  final Battery _battery;

  int _selectedRamBank = 0;

  int _selectedRomBank = 1;

  bool _ramWriteEnabled = false;

  Mbc5(this._cartridge, this._type, this._battery, this._romBanks,
      this._ramBanks) {
    _ram = [];
    final length = 0x2000 * max(_ramBanks, 1);
    for (int i = 0; i < length; i++) {
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
      _ramWriteEnabled = (value & 10 /* 0b1010 */) != 0;
      if (!_ramWriteEnabled) {
        _battery.saveRam(_ram);
      }
    } else if (address >= 0x2000 && address < 0x3000) {
      _selectedRomBank = (_selectedRomBank & 0x100) | value;
    } else if (address >= 0x3000 && address < 0x4000) {
      _selectedRomBank = (_selectedRomBank & 0x0ff) | ((value & 1) << 8);
    } else if (address >= 0x4000 && address < 0x6000) {
      int bank = value & 0x0f;
      if (bank < _ramBanks) {
        _selectedRamBank = bank;
      }
    } else if (address >= 0xa000 && address < 0xc000 && _ramWriteEnabled) {
      int ramAddress = _getRamAddress(address);
      if (ramAddress < _ram.length) {
        _ram[ramAddress] = value;
      }
    }
  }

  @override
  int getByte(int address) {
    if (address >= 0x0000 && address < 0x4000) {
      return _getRomByte(0, address);
    } else if (address >= 0x4000 && address < 0x8000) {
      return _getRomByte(_selectedRomBank, address - 0x4000);
    } else if (address >= 0xa000 && address < 0xc000) {
      int ramAddress = _getRamAddress(address);
      if (ramAddress < _ram.length) {
        return _ram[ramAddress];
      } else {
        return 0xff;
      }
    } else {
      throw Exception(address.toHex());
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
    return _selectedRamBank * 0x2000 + (address - 0xa000);
  }
}
