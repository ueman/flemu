import 'package:gb_emulator/gameboy.dart';

class LengthCounter {
  static const int _divider = ticksPerSecond ~/ 256;

  final int _fullLength;

  int _length = 0;

  int _i = 0;

  bool _enabled = false;

  LengthCounter(this._fullLength);

  void start() {
    _i = 8192;
  }

  void tick() {
    if (++_i == _divider) {
      _i = 0;
      if (_enabled && _length > 0) {
        _length--;
      }
    }
  }

  void setLength(int length) {
    if (length == 0) {
      _length = _fullLength;
    } else {
      _length = length;
    }
  }

  void setNr4(int value) {
    bool enable = (value & (1 << 6)) != 0;
    bool trigger = (value & (1 << 7)) != 0;

    if (_enabled) {
      if (_length == 0 && trigger) {
        if (enable && _i < _divider / 2) {
          setLength(_fullLength - 1);
        } else {
          setLength(_fullLength);
        }
      }
    } else if (enable) {
      if (_length > 0 && _i < _divider / 2) {
        _length--;
      }
      if (_length == 0 && trigger && _i < _divider / 2) {
        setLength(_fullLength - 1);
      }
    } else {
      if (_length == 0 && trigger) {
        setLength(_fullLength);
      }
    }
    _enabled = enable;
  }

  int get value => _length;

  bool get isEnabled => _enabled;

  @override
  String toString() {
    return "LengthCounter[l=$_length,f=$_fullLength,c=$_i,${_enabled ? 'enabled' : 'disabled'}]";
  }

  void reset() {
    _enabled = true;
    _i = 0;
    _length = 0;
  }
}
