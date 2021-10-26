class PolynomialCounter {
  int _shiftedDivisor = 0;

  int _i = 0;

  void setNr43(int value) {
    int clockShift = value >> 4;
    int divisor;
    switch (value & 7 /* 0b111 */) {
      case 0:
        divisor = 8;
        break;

      case 1:
        divisor = 16;
        break;

      case 2:
        divisor = 32;
        break;

      case 3:
        divisor = 48;
        break;

      case 4:
        divisor = 64;
        break;

      case 5:
        divisor = 80;
        break;

      case 6:
        divisor = 96;
        break;

      case 7:
        divisor = 112;
        break;

      default:
        throw Exception('IllegalState');
    }
    _shiftedDivisor = divisor << clockShift;
    _i = 1;
  }

  bool tick() {
    if (--_i == 0) {
      _i = _shiftedDivisor;
      return true;
    } else {
      return false;
    }
  }
}
