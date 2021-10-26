import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/memory/ram.dart';
import 'package:gb_emulator/sound/abstract_sound_mode.dart';
import 'package:gb_emulator/sound/sound_mode_1.dart';
import 'package:gb_emulator/sound/sound_mode_2.dart';
import 'package:gb_emulator/sound/sound_mode_3.dart';
import 'package:gb_emulator/sound/sound_mode_4.dart';
import 'package:gb_emulator/sound/sound_output.dart';

class Sound implements AddressSpace {
  late final List<AbstractSoundMode> _allModes = [
    SoundMode1(gbc),
    SoundMode2(gbc),
    SoundMode3(gbc),
    SoundMode4(gbc),
  ];

  final Ram _r = Ram(0xff24, 0x03);

  final SoundOutput _output;

  List<int> channels = []; // new int[4];

  bool _enabled = false;

  List<bool> overridenEnabled = [true, true, true, true];

  final bool gbc;

  Sound(this._output, this.gbc);

  void tick() {
    if (!_enabled) {
      return;
    }
    for (int i = 0; i < _allModes.length; i++) {
      AbstractSoundMode m = _allModes[i];
      channels[i] = m.tick();
    }

    int selection = _r.getByte(0xff25);
    int left = 0;
    int right = 0;
    for (int i = 0; i < 4; i++) {
      if (!overridenEnabled[i]) {
        continue;
      }
      if ((selection & (1 << i + 4)) != 0) {
        left += channels[i];
      }
      if ((selection & (1 << i)) != 0) {
        right += channels[i];
      }
    }
    left ~/= 4;
    right ~/= 4;

    int volumes = _r.getByte(0xff24);
    left *= ((volumes >> 4) & 7 /* 0b111 */);
    right *= (volumes & 7 /* 0b111 */);

    _output.play(left, right);
  }

  AddressSpace? _getAddressSpace(int address) {
    for (AbstractSoundMode m in _allModes) {
      if (m.accepts(address)) {
        return m;
      }
    }
    if (_r.accepts(address)) {
      return _r;
    }
    return null;
  }

  @override
  bool accepts(int address) {
    return _getAddressSpace(address) != null;
  }

  @override
  void setByte(int address, int value) {
    if (address == 0xff26) {
      if ((value & (1 << 7)) == 0) {
        if (_enabled) {
          _enabled = false;
          _stop();
        }
      } else {
        if (!_enabled) {
          _enabled = true;
          _start();
        }
      }
      return;
    }

    AddressSpace? s = _getAddressSpace(address);
    if (s == null) {
      throw Exception('IllegalArgument');
    }
    s.setByte(address, value);
  }

  @override
  int getByte(int address) {
    int result;
    if (address == 0xff26) {
      result = 0;
      for (int i = 0; i < _allModes.length; i++) {
        result |= _allModes[i].isEnabled() ? (1 << i) : 0;
      }
      result |= _enabled ? (1 << 7) : 0;
    } else {
      result = _getUnmaskedByte(address);
    }
    return result | MASKS[address - 0xff10];
  }

  int _getUnmaskedByte(int address) {
    AddressSpace? s = _getAddressSpace(address);
    if (s == null) {
      throw Exception('IllegalArgument');
    }
    return s.getByte(address);
  }

  void _start() {
    for (int i = 0xff10; i <= 0xff25; i++) {
      int v = 0;
      // lengths should be preserved
      if (i == 0xff11 || i == 0xff16 || i == 0xff20) {
        // channel 1, 2, 4 lengths
        v = _getUnmaskedByte(i) & 63; //0b00111111;
      } else if (i == 0xff1b) {
        // channel 3 length
        v = _getUnmaskedByte(i);
      }
      setByte(i, v);
    }
    for (AbstractSoundMode m in _allModes) {
      m.start();
    }
    _output.start();
  }

  void _stop() {
    _output.stop();
    for (AbstractSoundMode s in _allModes) {
      s.stop();
    }
  }

  void enableChannel(int i, bool enabled) {
    overridenEnabled[i] = enabled;
  }
}

const MASKS = [
  0x80,
  0x3f,
  0x00,
  0xff,
  0xbf,
  0xff,
  0x3f,
  0x00,
  0xff,
  0xbf,
  0x7f,
  0xff,
  0x9f,
  0xff,
  0xbf,
  0xff,
  0xff,
  0x00,
  0x00,
  0xbf,
  0x00,
  0x00,
  0x70,
  0xff,
  0xff,
  0xff,
  0xff,
  0xff,
  0xff,
  0xff,
  0xff,
  0xff,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
];
