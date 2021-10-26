import 'package:gb_emulator/gameboy.dart';

class VolumeEnvelope {
  int _initialVolume = 0;

  int _envelopeDirection = 0;

  int _sweep = 0;

  int _volume = 0;

  int _i = 0;

  bool _finished = false;

  void setNr2(int register) {
    _initialVolume = register >> 4;
    _envelopeDirection = (register & (1 << 3)) == 0 ? -1 : 1;
    _sweep = register & 7 /* 0b111 */;
  }

  bool isEnabled() {
    return _sweep > 0;
  }

  void start() {
    _finished = true;
    _i = 8192;
  }

  void trigger() {
    _volume = _initialVolume;
    _i = 0;
    _finished = false;
  }

  void tick() {
    if (_finished) {
      return;
    }
    if ((_volume == 0 && _envelopeDirection == -1) ||
        (_volume == 15 && _envelopeDirection == 1)) {
      _finished = true;
      return;
    }
    if (++_i == _sweep * ticksPerSecond / 64) {
      _i = 0;
      _volume += _envelopeDirection;
    }
  }

  int getVolume() {
    if (isEnabled()) {
      return _volume;
    } else {
      return _initialVolume;
    }
  }
}
