import 'package:gb_emulator/cpu/bit_utils.dart';

class Flags {
  static const int zPos = 7;

  static const int nPos = 6;

  static const int hPos = 5;

  static const int cPos = 4;

  int flagsByte = 0;

  bool isZ() => getBit(flagsByte, zPos);

  bool isN() => getBit(flagsByte, nPos);

  bool isH() => getBit(flagsByte, hPos);

  bool isC() => getBit(flagsByte, cPos);

  void setZ(bool z) => flagsByte = setBit(flagsByte, zPos, z);

  void setN(bool n) => flagsByte = setBit(flagsByte, nPos, n);

  void setH(bool h) => flagsByte = setBit(flagsByte, hPos, h);

  void setC(bool c) => flagsByte = setBit(flagsByte, cPos, c);

  void setFlagsByte(int flags) {
    assertIsByte("flags", flags);
    flagsByte = flags & 0xf0;
  }

  @override
  String toString() {
    return '${isZ() ? 'Z' : '-'}'
        '${isN() ? 'N' : '-'}'
        '${isH() ? 'H' : '-'}'
        '${isC() ? 'C' : '-'}'
        "----";
  }
}
