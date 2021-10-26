class Lfsr {
  int _lfsr = 0;

  Lfsr() {
    reset();
  }

  void start() {
    reset();
  }

  void reset() {
    _lfsr = 0x7fff;
  }

  int nextBit(bool widthMode7) {
    bool x = ((_lfsr & 1) ^ ((_lfsr & 2) >> 1)) != 0;
    _lfsr = _lfsr >> 1;
    _lfsr = _lfsr | (x ? (1 << 14) : 0);
    if (widthMode7) {
      _lfsr = _lfsr | (x ? (1 << 6) : 0);
    }
    return 1 & ~_lfsr;
  }

  int getValue() {
    return _lfsr;
  }
}
