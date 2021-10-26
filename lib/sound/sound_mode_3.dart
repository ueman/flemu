import 'package:gb_emulator/memory/ram.dart';
import 'package:gb_emulator/sound/abstract_sound_mode.dart';

class SoundMode3 extends AbstractSoundMode {
  final Ram _waveRam = Ram(0xff30, 0x10);

  int _freqDivider = 0;

  int _lastOutput = 0;

  int _i = 0;

  int _ticksSinceRead = 65536;

  int _lastReadAddr = 0;

  int _buffer = 0;

  bool _triggered = false;

  SoundMode3(bool gbc) : super(0xff1a, 256, gbc) {
    for (int v in gbc ? cgbWave : dmgWave) {
      _waveRam.setByte(0xff30, v);
    }
  }

  @override
  bool accepts(int address) {
    return _waveRam.accepts(address) || super.accepts(address);
  }

  @override
  int getByte(int address) {
    if (!_waveRam.accepts(address)) {
      return super.getByte(address);
    }
    if (!isEnabled()) {
      return _waveRam.getByte(address);
    } else if (_waveRam.accepts(_lastReadAddr) &&
        (gbc || _ticksSinceRead < 2)) {
      return _waveRam.getByte(_lastReadAddr);
    } else {
      return 0xff;
    }
  }

  @override
  void setByte(int address, int value) {
    if (!_waveRam.accepts(address)) {
      super.setByte(address, value);
      return;
    }
    if (!isEnabled()) {
      _waveRam.setByte(address, value);
    } else if (_waveRam.accepts(_lastReadAddr) &&
        (gbc || _ticksSinceRead < 2)) {
      _waveRam.setByte(_lastReadAddr, value);
    }
  }

  @override
  void setNr0(int value) {
    super.setNr0(value);
    dacEnabled = (value & (1 << 7)) != 0;
    channelEnabled &= dacEnabled;
  }

  @override
  void setNr1(int value) {
    super.setNr1(value);
    length.setLength(256 - value);
  }

  @override
  void setNr4(int value) {
    if (!gbc && (value & (1 << 7)) != 0) {
      if (isEnabled() && _freqDivider == 2) {
        int pos = _i ~/ 2;
        if (pos < 4) {
          _waveRam.setByte(0xff30, _waveRam.getByte(0xff30 + pos));
        } else {
          pos = pos & ~3;
          for (int j = 0; j < 4; j++) {
            _waveRam.setByte(
                0xff30 + j, _waveRam.getByte(0xff30 + ((pos + j) % 0x10)));
          }
        }
      }
    }
    super.setNr4(value);
  }

  @override
  void start() {
    _i = 0;
    _buffer = 0;
    if (gbc) {
      length.reset();
    }
    length.start();
  }

  @override
  void trigger() {
    _i = 0;
    _freqDivider = 6;
    _triggered = !gbc;
    if (gbc) {
      _getWaveEntry();
    }
  }

  @override
  int tick() {
    _ticksSinceRead++;
    if (!updateLength()) {
      return 0;
    }
    if (!dacEnabled) {
      return 0;
    }

    if ((getNr0() & (1 << 7)) == 0) {
      return 0;
    }

    if (--_freqDivider == 0) {
      _resetFreqDivider();
      if (_triggered) {
        _lastOutput = (_buffer >> 4) & 0x0f;
        _triggered = false;
      } else {
        _lastOutput = _getWaveEntry();
      }
      _i = (_i + 1) % 32;
    }
    return _lastOutput;
  }

  int _getVolume() {
    return (getNr2() >> 5) & 3; //0b11;
  }

  int _getWaveEntry() {
    _ticksSinceRead = 0;
    _lastReadAddr = 0xff30 + _i ~/ 2;
    _buffer = _waveRam.getByte(_lastReadAddr);
    int b = _buffer;
    if (_i % 2 == 0) {
      b = (b >> 4) & 0x0f;
    } else {
      b = b & 0x0f;
    }
    switch (_getVolume()) {
      case 0:
        return 0;
      case 1:
        return b;
      case 2:
        return b >> 1;
      case 3:
        return b >> 2;
      default:
        throw Exception('IllegalState');
    }
  }

  void _resetFreqDivider() {
    _freqDivider = getFrequency() * 2;
  }
}

const dmgWave = [
  0x84,
  0x40,
  0x43,
  0xaa,
  0x2d,
  0x78,
  0x92,
  0x3c,
  0x60,
  0x59,
  0x59,
  0xb0,
  0x34,
  0xb8,
  0x2e,
  0xda
];

const cgbWave = [
  0x00,
  0xff,
  0x00,
  0xff,
  0x00,
  0xff,
  0x00,
  0xff,
  0x00,
  0xff,
  0x00,
  0xff,
  0x00,
  0xff,
  0x00,
  0xff
];
