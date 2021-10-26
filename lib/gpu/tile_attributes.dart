import 'package:gb_emulator/gpu/gpu_register.dart';

List<TileAttributes> _fill() {
  var list = <TileAttributes>[];
  for (int i = 0; i < 256; i++) {
    list[i] = TileAttributes._(i);
  }
  return list;
}

class TileAttributes {
  static final TileAttributes empty = TileAttributes._(0);

  static late final List<TileAttributes> _attributes = _fill();

  final int _value;

  TileAttributes._(this._value);

  static TileAttributes valueOf(int value) {
    return _attributes[value];
  }

  bool isPriority() {
    return (_value & (1 << 7)) != 0;
  }

  bool isYflip() {
    return (_value & (1 << 6)) != 0;
  }

  bool isXflip() {
    return (_value & (1 << 5)) != 0;
  }

  GpuRegister getDmgPalette() {
    return (_value & (1 << 4)) == 0
        ? const GpuRegister.obp0()
        : const GpuRegister.obp1();
  }

  int getBank() {
    return (_value & (1 << 3)) == 0 ? 0 : 1;
  }

  int getColorPaletteIndex() {
    return _value & 0x07;
  }
}
