import 'package:gb_emulator/address_space.dart';

class Lcdc implements AddressSpace {
  int _value = 0x91;

  bool isBgAndWindowDisplay() {
    return (_value & 0x01) != 0;
  }

  bool isObjDisplay() {
    return (_value & 0x02) != 0;
  }

  int getSpriteHeight() {
    return (_value & 0x04) == 0 ? 8 : 16;
  }

  int getBgTileMapDisplay() {
    return (_value & 0x08) == 0 ? 0x9800 : 0x9c00;
  }

  int getBgWindowTileData() {
    return (_value & 0x10) == 0 ? 0x9000 : 0x8000;
  }

  bool isBgWindowTileDataSigned() {
    return (_value & 0x10) == 0;
  }

  bool isWindowDisplay() {
    return (_value & 0x20) != 0;
  }

  int getWindowTileMapDisplay() {
    return (_value & 0x40) == 0 ? 0x9800 : 0x9c00;
  }

  bool isLcdEnabled() {
    return (_value & 0x80) != 0;
  }

  @override
  bool accepts(int address) {
    return address == 0xff40;
  }

  @override
  void setByte(int address, int value) {
    assert(address == 0xff40);
    _value = value;
  }

  @override
  int getByte(int address) {
    assert(address == 0xff40);
    return _value;
  }

  void set(int value) {
    _value = value;
  }

  int get() {
    return _value;
  }
}
