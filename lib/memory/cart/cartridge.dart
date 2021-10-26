import 'dart:io';

import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/gameboy_options.dart';
import 'package:gb_emulator/int_x.dart';
import 'package:gb_emulator/memory/boot_rom.dart';
import 'package:gb_emulator/memory/cart/battery/battery.dart';
import 'package:gb_emulator/memory/cart/cartridge_type.dart';
import 'package:gb_emulator/memory/cart/type/mbc1.dart';
import 'package:gb_emulator/memory/cart/type/mbc2.dart';
import 'package:gb_emulator/memory/cart/type/mbc3.dart';
import 'package:gb_emulator/memory/cart/type/mbc5.dart';
import 'package:gb_emulator/memory/cart/type/rom.dart';
import 'package:path/path.dart';

enum GameboyTypeFlag {
  UNIVERSAL,
  CGB,
  NON_CGB,
}

GameboyTypeFlag getFlag(int value) {
  if (value == 0x80) {
    return GameboyTypeFlag.UNIVERSAL;
  } else if (value == 0xc0) {
    return GameboyTypeFlag.CGB;
  } else {
    return GameboyTypeFlag.NON_CGB;
  }
}

class Cartridge implements AddressSpace {
  //private static final Logger LOG = LoggerFactory.getLogger(Cartridge.class);

  late final AddressSpace _addressSpace;

  late final GameboyTypeFlag _gameboyType;

  late final bool _gbc;

  late final String _title;

  int _dmgBoostrap = 0;

  Cartridge(GameboyOptions options) {
    File file = options.romFile;
    List<int> rom = _loadFile(file);
    final type = CartridgeType.getById(rom[0x0147]);
    _title = _getTitle(rom);
    // LOG.debug("Cartridge {}, type: {}", title, type);
    _gameboyType = getFlag(rom[0x0143]);
    int romBanks = getRomBanks(rom[0x0148]);
    int ramBanks = getRamBanks(rom[0x0149]);
    if (ramBanks == 0 && type.isRam()) {
      // LOG.warn("RAM bank is defined to 0. Overriding to 1.");
      ramBanks = 1;
    }
    // LOG.debug("ROM banks: {}, RAM banks: {}", romBanks, ramBanks);

    Battery battery = NullBattery();
    if (type.isBattery() && options.isSupportBatterySaves) {
      // battery = FileBattery(file.getParentFile(), FilenameUtils.removeExtension(file.getName()));
    }

    if (type.isMbc1()) {
      _addressSpace = Mbc1(rom, type, battery, romBanks, ramBanks);
    } else if (type.isMbc2()) {
      _addressSpace = Mbc2(rom, type, battery, romBanks);
    } else if (type.isMbc3()) {
      _addressSpace = Mbc3(rom, type, battery, romBanks, ramBanks);
    } else if (type.isMbc5()) {
      _addressSpace = Mbc5(rom, type, battery, romBanks, ramBanks);
    } else {
      _addressSpace = Rom(rom, type, romBanks, ramBanks);
    }

    _dmgBoostrap = options.useBootstrap ? 0 : 1;
    if (options.forceCgb) {
      _gbc = true;
    } else if (_gameboyType == GameboyTypeFlag.NON_CGB) {
      _gbc = false;
    } else if (_gameboyType == GameboyTypeFlag.CGB) {
      _gbc = true;
    } else {
      // UNIVERSAL
      _gbc = !options.forceDmg;
    }
  }

  String _getTitle(List<int> rom) {
    var t = "";
    for (int i = 0x0134; i < 0x0143; i++) {
      final c = String.fromCharCode(rom[i]);
      if (c == "0") {
        break;
      }
      t += c;
    }
    return t.toString();
  }

  String getTitle() {
    return _title;
  }

  bool isGbc() {
    return _gbc;
  }

  @override
  bool accepts(int address) {
    return _addressSpace.accepts(address) || address == 0xff50;
  }

  @override
  void setByte(int address, int value) {
    if (address == 0xff50) {
      _dmgBoostrap = 1;
    } else {
      _addressSpace.setByte(address, value);
    }
  }

  @override
  int getByte(int address) {
    if (_dmgBoostrap == 0 && !_gbc && (address >= 0x0000 && address < 0x0100)) {
      return gameboyClassic[address];
    } else if (_dmgBoostrap == 0 &&
        _gbc &&
        address >= 0x000 &&
        address < 0x0100) {
      return gameboyColor[address];
    } else if (_dmgBoostrap == 0 &&
        _gbc &&
        address >= 0x200 &&
        address < 0x0900) {
      return gameboyColor[address - 0x0100];
    } else if (address == 0xff50) {
      return 0xff;
    } else {
      return _addressSpace.getByte(address);
    }
  }

  static List<int> _loadFile(File file) {
    String ext = extension(file.path);
    // for now no zip support
    return _load(file);
  }

  static List<int> _load(File file) {
    final intArray = file.readAsBytesSync();
    return intArray;
  }

  static int getRomBanks(int id) {
    switch (id) {
      case 0:
        return 2;

      case 1:
        return 4;

      case 2:
        return 8;

      case 3:
        return 16;

      case 4:
        return 32;

      case 5:
        return 64;

      case 6:
        return 128;

      case 7:
        return 256;

      case 0x52:
        return 72;

      case 0x53:
        return 80;

      case 0x54:
        return 96;

      default:
        throw Exception("Unsupported ROM size: ${id.toHex()}");
    }
  }

  static int getRamBanks(int id) {
    switch (id) {
      case 0:
        return 0;

      case 1:
        return 1;

      case 2:
        return 1;

      case 3:
        return 4;

      case 4:
        return 16;

      default:
        throw Exception("Unsupported RAM size: ${id.toHex()}");
    }
  }
}
