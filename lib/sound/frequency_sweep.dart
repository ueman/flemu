import 'package:gb_emulator/gameboy.dart';

class FrequencySweep {
  static const int _divider = ticksPerSecond ~/ 128;

  // sweep parameters
  int _period = 0;

  bool _negate = false;

  int _shift = 0;

  // current process variables
  int _timer = 0;

  int _shadowFreq = 0;

  int _nr13 = 0, _nr14 = 0;

  int _i = 0;

  bool _overflow = false;

  bool _counterEnabled = false;

  bool _negging = false;

  void start() {
    _counterEnabled = false;
    _i = 8192;
  }

  void trigger() {
    _negging = false;
    _overflow = false;

    _shadowFreq = _nr13 | ((_nr14 & 7 /* 0b111 */) << 8);
    _timer = _period == 0 ? 8 : _period;
    _counterEnabled = _period != 0 || _shift != 0;

    if (_shift > 0) {
      _calculate();
    }
  }

  void setNr10(int value) {
    _period = (value >> 4) & 7; // 0b111;
    _negate = (value & (1 << 3)) != 0;
    _shift = value & 7; // 0b111;
    if (_negging && !_negate) {
      _overflow = true;
    }
  }

  void setNr13(int value) {
    _nr13 = value;
  }

  void setNr14(int value) {
    _nr14 = value;
    if ((value & (1 << 7)) != 0) {
      trigger();
    }
  }

  int getNr13() {
    return _nr13;
  }

  int getNr14() {
    return _nr14;
  }

  void tick() {
    if (++_i == _divider) {
      _i = 0;
      if (!_counterEnabled) {
        return;
      }
      if (--_timer == 0) {
        _timer = _period == 0 ? 8 : _period;
        if (_period != 0) {
          int newFreq = _calculate();
          if (!_overflow && _shift != 0) {
            _shadowFreq = newFreq;
            _nr13 = _shadowFreq & 0xff;
            _nr14 = (_shadowFreq & 0x700) >> 8;
            _calculate();
          }
        }
      }
    }
  }

  int _calculate() {
    int freq = _shadowFreq >> _shift;
    if (_negate) {
      freq = _shadowFreq - freq;
      _negging = true;
    } else {
      freq = _shadowFreq + freq;
    }
    if (freq > 2047) {
      _overflow = true;
    }
    return freq;
  }

  bool isEnabled() {
    return !_overflow;
  }
}
