import 'package:gb_emulator/sound/abstract_sound_mode.dart';
import 'package:gb_emulator/sound/lfsr.dart';
import 'package:gb_emulator/sound/polynomial_counter.dart';
import 'package:gb_emulator/sound/volume_envelope.dart';

class SoundMode4 extends AbstractSoundMode {
  final VolumeEnvelope _volumeEnvelope = VolumeEnvelope();

  final PolynomialCounter _polynomialCounter = PolynomialCounter();

  int _lastResult = 0;

  final Lfsr _lfsr = Lfsr();

  SoundMode4(bool gbc) : super(0xff1f, 64, gbc);

  @override
  void start() {
    if (gbc) {
      length.reset();
    }
    length.start();
    _lfsr.start();
    _volumeEnvelope.start();
  }

  @override
  void trigger() {
    _lfsr.reset();
    _volumeEnvelope.trigger();
  }

  @override
  int tick() {
    _volumeEnvelope.tick();

    if (!updateLength()) {
      return 0;
    }
    if (!dacEnabled) {
      return 0;
    }

    if (_polynomialCounter.tick()) {
      _lastResult = _lfsr.nextBit((nr3 & (1 << 3)) != 0);
    }
    return _lastResult * _volumeEnvelope.getVolume();
  }

  @override
  void setNr1(int value) {
    super.setNr1(value);
    length.setLength(64 - (value & 63 /* 0b00111111 */));
  }

  @override
  void setNr2(int value) {
    super.setNr2(value);
    _volumeEnvelope.setNr2(value);
    dacEnabled = (value & 248 /* 0b11111000 */) != 0;
    channelEnabled &= dacEnabled;
  }

  @override
  void setNr3(int value) {
    super.setNr3(value);
    _polynomialCounter.setNr43(value);
  }
}
