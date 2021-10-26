import 'package:gb_emulator/int_x.dart';

class CartridgeType {
  const CartridgeType.rom()
      : id = 0x00,
        name = 'rom';
  const CartridgeType.romMbc1()
      : id = 0x01,
        name = 'romMbc1';
  const CartridgeType.romMbc1Ram()
      : id = 0x02,
        name = 'romMbc1Ram';
  const CartridgeType.romMbc1RamBattery()
      : id = 0x03,
        name = 'romMbc1RamBattery';
  const CartridgeType.romMbc2()
      : id = 0x05,
        name = 'romMbc2';
  const CartridgeType.romMbc2Battery()
      : id = 0x06,
        name = 'romMbc2Battery';
  const CartridgeType.romRam()
      : id = 0x08,
        name = 'romRam';
  const CartridgeType.romRamBattery()
      : id = 0x09,
        name = 'romRamBattery';
  const CartridgeType.romMmm01()
      : id = 0x0b,
        name = 'romMmm01';
  const CartridgeType.romMmm01Sram()
      : id = 0x0c,
        name = 'romMmm01Sram';
  const CartridgeType.romMmm01SramBattery()
      : id = 0x0d,
        name = 'romMmm01SramBattery';
  const CartridgeType.romMbc3TimerBattery()
      : id = 0x0f,
        name = 'romMbc3TimerBattery';
  const CartridgeType.romMbc3TimerRamBattery()
      : id = 0x10,
        name = 'romMbc3TimerRamBattery';
  const CartridgeType.romMbc3()
      : id = 0x11,
        name = 'romMbc3';
  const CartridgeType.romMbc3Ram()
      : id = 0x12,
        name = 'romMbc3Ram';
  const CartridgeType.romMbc3RamBattery()
      : id = 0x13,
        name = 'romMbc3RamBattery';
  const CartridgeType.romMbc5()
      : id = 0x19,
        name = 'romMbc5';
  const CartridgeType.romMbc5Ram()
      : id = 0x1a,
        name = 'romMbc5Ram';
  const CartridgeType.romMbc5RamBattery()
      : id = 0x01b,
        name = 'romMbc5RamBattery';
  const CartridgeType.romMbc5Rumble()
      : id = 0x1c,
        name = 'romMbc5Rumble';
  const CartridgeType.romMbc5RumbleSram()
      : id = 0x1d,
        name = 'romMbc5RumbleSram';
  const CartridgeType.romMbc5RumbleSramBattery()
      : id = 0x1e,
        name = 'romMbc5RumbleSramBattery';

  static const List<CartridgeType> values = [
    CartridgeType.rom(),
    CartridgeType.romMbc1(),
    CartridgeType.romMbc1Ram(),
    CartridgeType.romMbc1RamBattery(),
    CartridgeType.romMbc2(),
    CartridgeType.romMbc2Battery(),
    CartridgeType.romRam(),
    CartridgeType.romRamBattery(),
    CartridgeType.romMmm01(),
    CartridgeType.romMmm01Sram(),
    CartridgeType.romMmm01SramBattery(),
    CartridgeType.romMbc3TimerBattery(),
    CartridgeType.romMbc3TimerRamBattery(),
    CartridgeType.romMbc3(),
    CartridgeType.romMbc3Ram(),
    CartridgeType.romMbc3RamBattery(),
    CartridgeType.romMbc5(),
    CartridgeType.romMbc5Ram(),
    CartridgeType.romMbc5RamBattery(),
    CartridgeType.romMbc5Rumble(),
    CartridgeType.romMbc5RumbleSram(),
    CartridgeType.romMbc5RumbleSramBattery(),
  ];

  final int id;
  final String name;

  bool isMbc1() {
    return nameContainsSegment("MBC1");
  }

  bool isMbc2() {
    return nameContainsSegment("MBC2");
  }

  bool isMbc3() {
    return nameContainsSegment("MBC3");
  }

  bool isMbc5() {
    return nameContainsSegment("MBC5");
  }

  bool isMmm01() {
    return nameContainsSegment("MMM01");
  }

  bool isRam() {
    return nameContainsSegment("RAM");
  }

  bool isSram() {
    return nameContainsSegment("SRAM");
  }

  bool isTimer() {
    return nameContainsSegment("TIMER");
  }

  bool isBattery() {
    return nameContainsSegment("BATTERY");
  }

  bool isRumble() {
    return nameContainsSegment("RUMBLE");
  }

  bool nameContainsSegment(String segment) {
    return name.toLowerCase().contains(segment.toLowerCase());
  }

  static CartridgeType getById(int id) {
    for (CartridgeType t in values) {
      if (t.id == id) {
        return t;
      }
    }
    throw Exception("Unsupported cartridge type: " + id.toHex());
  }
}
