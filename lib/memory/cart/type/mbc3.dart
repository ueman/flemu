import 'dart:math';

import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/int_x.dart';
import 'package:gb_emulator/memory/cart/battery/battery.dart';
import 'package:gb_emulator/memory/cart/cartridge_type.dart';
import 'package:gb_emulator/memory/cart/rtc/clock.dart';
import 'package:gb_emulator/memory/cart/rtc/real_time_clock.dart';

class Mbc3 implements AddressSpace {
  final CartridgeType _type;

  final int _ramBanks;

  final List<int> _cartridge;

  late final List<int> _ram;

  late final RealTimeClock _clock;

  final Battery _battery;

  int _selectedRamBank = 0;

  int _selectedRomBank = 1;

  bool _ramWriteEnabled = false;

  int _latchClockReg = 0xff;

  bool _clockLatched = false;

  Mbc3(this._cartridge, this._type, this._battery, int romBanks,
      this._ramBanks) {
    _ram = [];
    final length = 0x2000 * max(_ramBanks, 1);
    for (int i = 0; i < length; i++) {
      _ram[i] = 0xff;
    }

    _clock = RealTimeClock(SystemClock());

    List<int> clockData = []; //new long[12];
    _battery.loadRamWithClock(_ram, clockData);
    _clock.deserialize(clockData);
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
        _battery.saveRamWithClock(_ram, _clock.serialize());
      }
    } else if (address >= 0x2000 && address < 0x4000) {
      int bank = value & 127; // 0b01111111
      _selectRomBank(bank);
    } else if (address >= 0x4000 && address < 0x6000) {
      _selectedRamBank = value;
    } else if (address >= 0x6000 && address < 0x8000) {
      if (value == 0x01 && _latchClockReg == 0x00) {
        if (_clockLatched) {
          _clock.unlatch();
          _clockLatched = false;
        } else {
          _clock.latch();
          _clockLatched = true;
        }
      }
      _latchClockReg = value;
    } else if (address >= 0xa000 &&
        address < 0xc000 &&
        _ramWriteEnabled &&
        _selectedRamBank < 4) {
      int ramAddress = _getRamAddress(address);
      if (ramAddress < _ram.length) {
        _ram[ramAddress] = value;
      }
    } else if (address >= 0xa000 &&
        address < 0xc000 &&
        _ramWriteEnabled &&
        _selectedRamBank >= 4) {
      _setTimer(value);
    }
  }

  void _selectRomBank(int bank) {
    if (bank == 0) {
      bank = 1;
    }
    _selectedRomBank = bank;
  }

  @override
  int getByte(int address) {
    if (address >= 0x0000 && address < 0x4000) {
      return _getRomByte(0, address);
    } else if (address >= 0x4000 && address < 0x8000) {
      return _getRomByte(_selectedRomBank, address - 0x4000);
    } else if (address >= 0xa000 && address < 0xc000 && _selectedRamBank < 4) {
      int ramAddress = _getRamAddress(address);
      if (ramAddress < _ram.length) {
        return _ram[ramAddress];
      } else {
        return 0xff;
      }
    } else if (address >= 0xa000 && address < 0xc000 && _selectedRamBank >= 4) {
      return _getTimer();
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

  int _getTimer() {
    switch (_selectedRamBank) {
      case 0x08:
        return _clock.getSeconds();

      case 0x09:
        return _clock.getMinutes();

      case 0x0a:
        return _clock.getHours();

      case 0x0b:
        return _clock.getDayCounter() & 0xff;

      case 0x0c:
        int result = ((_clock.getDayCounter() & 0x100) >> 8);
        result |= _clock.isHalt() ? (1 << 6) : 0;
        result |= _clock.isCounterOverflow() ? (1 << 7) : 0;
        return result;
    }
    return 0xff;
  }

  void _setTimer(int value) {
    int dayCounter = _clock.getDayCounter();
    switch (_selectedRamBank) {
      case 0x08:
        _clock.setSeconds(value);
        break;

      case 0x09:
        _clock.setMinutes(value);
        break;

      case 0x0a:
        _clock.setHours(value);
        break;

      case 0x0b:
        _clock.setDayCounter((dayCounter & 0x100) | (value & 0xff));
        break;

      case 0x0c:
        _clock.setDayCounter((dayCounter & 0xff) | ((value & 1) << 8));
        _clock.setHalt((value & (1 << 6)) != 0);
        if ((value & (1 << 7)) == 0) {
          _clock.clearCounterOverflow();
        }
        break;
    }
  }
}
