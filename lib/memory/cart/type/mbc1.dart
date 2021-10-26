import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/int_x.dart';
import 'package:gb_emulator/memory/cart/battery/battery.dart';
import 'package:gb_emulator/memory/cart/cartridge_type.dart';

class Mbc1 implements AddressSpace {
  final CartridgeType _type;

  final int _romBanks;

  final int _ramBanks;

  final List<int> _cartridge;

  late final List<int> _ram;

  final Battery _battery;

  late final bool _multicart;

  int _selectedRamBank = 0;

  int _selectedRomBank = 1;

  int _memoryModel = 0;

  bool _ramWriteEnabled = false;

  int _cachedRomBankFor0x0000 = -1;

  int _cachedRomBankFor0x4000 = -1;

  Mbc1(
    this._cartridge,
    this._type,
    this._battery,
    this._romBanks,
    this._ramBanks,
  ) {
    _multicart = _romBanks == 64 && _isMulticart(_cartridge);

    final length = 0x2000 * _ramBanks;
    _ram = []; //0x2000 * this._ramBanks;
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
      _ramWriteEnabled = (value & 15 /* 0b1111 */) == 10; //0b1010
      if (!_ramWriteEnabled) {
        _battery.saveRam(_ram);
      }
      // LOG.trace("RAM write: {}", ramWriteEnabled);
    } else if (address >= 0x2000 && address < 0x4000) {
      //LOG.trace("Low 5 bits of ROM bank: {}", (value & 0b00011111));
      int bank = _selectedRomBank & 96; //0b01100000;
      bank = bank | (value & 31); //0b00011111
      _selectRomBank(bank);
      _cachedRomBankFor0x0000 = _cachedRomBankFor0x4000 = -1;
    } else if (address >= 0x4000 && address < 0x6000 && _memoryModel == 0) {
      //LOG.trace("High 2 bits of ROM bank: {}", ((value & 0b11) << 5));
      int bank = _selectedRomBank & 31; // 0b00011111
      bank = bank | ((value & 3 /* 0b11 */) << 5);
      _selectRomBank(bank);
      _cachedRomBankFor0x0000 = _cachedRomBankFor0x4000 = -1;
    } else if (address >= 0x4000 && address < 0x6000 && _memoryModel == 1) {
      //LOG.trace("RAM bank: {}", (value & 0b11));
      int bank = value & 3; //0b11
      _selectedRamBank = bank;
      _cachedRomBankFor0x0000 = _cachedRomBankFor0x4000 = -1;
    } else if (address >= 0x6000 && address < 0x8000) {
      //LOG.trace("Memory mode: {}", (value & 1));
      _memoryModel = value & 1;
      _cachedRomBankFor0x0000 = _cachedRomBankFor0x4000 = -1;
    } else if (address >= 0xa000 && address < 0xc000 && _ramWriteEnabled) {
      int ramAddress = _getRamAddress(address);
      if (ramAddress < _ram.length) {
        _ram[ramAddress] = value;
      }
    }
  }

  void _selectRomBank(int bank) {
    _selectedRomBank = bank;
    //LOG.trace("Selected ROM bank: {}", selectedRomBank);
  }

  @override
  int getByte(int address) {
    if (address >= 0x0000 && address < 0x4000) {
      return _getRomByte(_getRomBankFor0x0000(), address);
    } else if (address >= 0x4000 && address < 0x8000) {
      return _getRomByte(_getRomBankFor0x4000(), address - 0x4000);
    } else if (address >= 0xa000 && address < 0xc000) {
      if (_ramWriteEnabled) {
        int ramAddress = _getRamAddress(address);
        if (ramAddress < _ram.length) {
          return _ram[ramAddress];
        } else {
          return 0xff;
        }
      } else {
        return 0xff;
      }
    } else {
      throw Exception(address.toHex());
    }
  }

  int _getRomBankFor0x0000() {
    if (_cachedRomBankFor0x0000 == -1) {
      if (_memoryModel == 0) {
        _cachedRomBankFor0x0000 = 0;
      } else {
        int bank = (_selectedRamBank << 5);
        if (_multicart) {
          bank >>= 1;
        }
        bank %= _romBanks;
        _cachedRomBankFor0x0000 = bank;
      }
    }
    return _cachedRomBankFor0x0000;
  }

  int _getRomBankFor0x4000() {
    if (_cachedRomBankFor0x4000 == -1) {
      int bank = _selectedRomBank;
      if (bank % 0x20 == 0) {
        bank++;
      }
      if (_memoryModel == 1) {
        bank &= 31; //0b00011111;
        bank |= (_selectedRamBank << 5);
      }
      if (_multicart) {
        bank = ((bank >> 1) & 0x30) | (bank & 0x0f);
      }
      bank %= _romBanks;
      _cachedRomBankFor0x4000 = bank;
    }
    return _cachedRomBankFor0x4000;
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
    if (_memoryModel == 0) {
      return address - 0xa000;
    } else {
      return (_selectedRamBank % _ramBanks) * 0x2000 + (address - 0xa000);
    }
  }

  static bool _isMulticart(List<int> rom) {
    int logoCount = 0;
    for (int i = 0; i < rom.length; i += 0x4000) {
      bool logoMatches = true;
      for (int j = 0; j < nintendoLogo.length; j++) {
        if (rom[i + 0x104 + j] != nintendoLogo[j]) {
          logoMatches = false;
          break;
        }
      }
      if (logoMatches) {
        logoCount++;
      }
    }
    return logoCount > 1;
  }

  static const List<int> nintendoLogo = [
    0xCE,
    0xED,
    0x66,
    0x66,
    0xCC,
    0x0D,
    0x00,
    0x0B,
    0x03,
    0x73,
    0x00,
    0x83,
    0x00,
    0x0C,
    0x00,
    0x0D,
    0x00,
    0x08,
    0x11,
    0x1F,
    0x88,
    0x89,
    0x00,
    0x0E,
    0xDC,
    0xCC,
    0x6E,
    0xE6,
    0xDD,
    0xDD,
    0xD9,
    0x99,
    0xBB,
    0xBB,
    0x67,
    0x63,
    0x6E,
    0x0E,
    0xEC,
    0xCC,
    0xDD,
    0xDC,
    0x99,
    0x9F,
    0xBB,
    0xB9,
    0x33,
    0x3E
  ];
}
