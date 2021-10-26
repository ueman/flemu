import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/int_x.dart';
import 'package:gb_emulator/sound/length_counter.dart';

abstract class AbstractSoundMode implements AddressSpace {
  final int offset;

  final bool gbc;

  bool channelEnabled = false;

  bool dacEnabled = false;

  int nr0 = 0, nr1 = 0, nr2 = 0, nr3 = 0, nr4 = 0;

  late LengthCounter length;

  AbstractSoundMode(this.offset, int _length, this.gbc) {
    length = LengthCounter(_length);
  }

  int tick();

  void trigger();

  bool isEnabled() {
    return channelEnabled && dacEnabled;
  }

  @override
  bool accepts(int address) {
    return address >= offset && address < offset + 5;
  }

  @override
  void setByte(int address, int value) {
    switch (address - offset) {
      case 0:
        setNr0(value);
        break;

      case 1:
        setNr1(value);
        break;

      case 2:
        setNr2(value);
        break;

      case 3:
        setNr3(value);
        break;

      case 4:
        setNr4(value);
        break;
    }
  }

  @override
  int getByte(int address) {
    switch (address - offset) {
      case 0:
        return getNr0();

      case 1:
        return getNr1();

      case 2:
        return getNr2();

      case 3:
        return getNr3();

      case 4:
        return getNr4();

      default:
        throw Exception("Illegal address for sound mode: ${address.toHex()}");
    }
  }

  void setNr0(int value) {
    nr0 = value;
  }

  void setNr1(int value) {
    nr1 = value;
  }

  void setNr2(int value) {
    nr2 = value;
  }

  void setNr3(int value) {
    nr3 = value;
  }

  void setNr4(int value) {
    nr4 = value;
    length.setNr4(value);
    if ((value & (1 << 7)) != 0) {
      channelEnabled = dacEnabled;
      trigger();
    }
  }

  int getNr0() {
    return nr0;
  }

  int getNr1() {
    return nr1;
  }

  int getNr2() {
    return nr2;
  }

  int getNr3() {
    return nr3;
  }

  int getNr4() {
    return nr4;
  }

  int getFrequency() {
    return 2048 - (getNr3() | ((getNr4() & 7 /* 0b111 */) << 8));
  }

  void start();

  void stop() {
    channelEnabled = false;
  }

  bool updateLength() {
    length.tick();
    if (!length.isEnabled) {
      return channelEnabled;
    }
    if (channelEnabled && length.value == 0) {
      channelEnabled = false;
    }
    return channelEnabled;
  }
}
