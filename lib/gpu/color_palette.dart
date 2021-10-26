import 'package:gb_emulator/address_space.dart';

class ColorPalette implements AddressSpace {
  late final int _indexAddr;

  late final int _dataAddr;

  List<List<int>> palettes =
      List.generate(8, (index) => List.generate(4, (index) => 0));
  final lengthX = 8;
  final lengthY = 4;

  int _index = 0;

  bool _autoIncrement = false;

  ColorPalette(int offset) {
    _indexAddr = offset;
    _dataAddr = offset + 1;
  }

  @override
  bool accepts(int address) {
    return address == _indexAddr || address == _dataAddr;
  }

  @override
  void setByte(int address, int value) {
    if (address == _indexAddr) {
      _index = value & 0x3f;
      _autoIncrement = (value & (1 << 7)) != 0;
    } else if (address == _dataAddr) {
      int color = palettes[_index ~/ 8][(_index % 8) ~/ 2];
      if (_index % 2 == 0) {
        color = (color & 0xff00) | value;
      } else {
        color = (color & 0x00ff) | (value << 8);
      }
      palettes[_index ~/ 8][(_index % 8) ~/ 2] = color;
      if (_autoIncrement) {
        _index = (_index + 1) & 0x3f;
      }
    } else {
      throw Exception("IllegalArgument");
    }
  }

  @override
  int getByte(int address) {
    if (address == _indexAddr) {
      return _index | (_autoIncrement ? 0x80 : 0x00) | 0x40;
    } else if (address == _dataAddr) {
      int color = palettes[_index ~/ 8][(_index % 8) ~/ 2];
      if (_index % 2 == 0) {
        return color & 0xff;
      } else {
        return (color >> 8) & 0xff;
      }
    } else {
      throw Exception("IllegalArgument");
    }
  }

  List<int> getPalette(int index) {
    return palettes[index];
  }

  @override
  String toString() {
    String b = '';
    for (int i = 0; i < 8; i++) {
      b += "$i: ";
      var palette = getPalette(i);
      for (int c in palette) {
        b += c.toString().padLeft(4);
        b += " ";
      }
      b = b.substring(0, b.length - 1) + "\n";
    }
    return b.toString();
  }

  void fillWithFF() {
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 4; j++) {
        palettes[i][j] = 0x7fff;
      }
    }
  }
}
