import 'package:gb_emulator/sound/abstract_sound_mode.dart';
import 'package:gb_emulator/sound/volume_envelope.dart';

class SoundMode2 extends AbstractSoundMode {
  int _freqDivider = 0;

  int _lastOutput = 0;

  int _i = 0;

  final VolumeEnvelope volumeEnvelope = VolumeEnvelope();

  SoundMode2(bool gbc) : super(0xff15, 64, gbc);

  @override
  void start() {
    _i = 0;
    if (gbc) {
      length.reset();
    }
    length.start();
    volumeEnvelope.start();
  }

  @override
  void trigger() {
    _i = 0;
    _freqDivider = 1;
    volumeEnvelope.trigger();
  }

  @override
  int tick() {
    volumeEnvelope.tick();

    bool e = true;
    e = updateLength() && e;
    e = dacEnabled && e;
    if (!e) {
      return 0;
    }

    if (--_freqDivider == 0) {
      _resetFreqDivider();
      _lastOutput = ((_getDuty() & (1 << _i)) >> _i);
      _i = (_i + 1) % 8;
    }
    return _lastOutput * volumeEnvelope.getVolume();
  }

  @override
  void setNr1(int value) {
    super.setNr1(value);
    length.setLength(64 - (value & 63 /* 0b00111111 */));
  }

  @override
  void setNr2(int value) {
    super.setNr2(value);
    volumeEnvelope.setNr2(value);
    dacEnabled = (value & 248 /* 0b11111000 */) != 0;
    channelEnabled &= dacEnabled;
  }

  int _getDuty() {
    switch (getNr1() >> 6) {
      case 0:
        return 1 /* 0b00000001 */;
      case 1:
        return 129 /* 0b10000001 */;
      case 2:
        return 135 /* 0b10000111 */;
      case 3:
        return 126 /* 0b01111110 */;
      default:
        throw Exception('IllegalState');
    }
  }

  void _resetFreqDivider() {
    _freqDivider = getFrequency() * 4;
  }
}
