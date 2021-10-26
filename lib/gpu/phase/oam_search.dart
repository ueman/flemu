import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/gpu/gpu_register.dart';
import 'package:gb_emulator/gpu/lcdc.dart';
import 'package:gb_emulator/gpu/phase/gpu_phase.dart';
import 'package:gb_emulator/memory/memory_registers.dart';

enum _State {
  READING_Y,
  READING_X,
}

class SpritePosition {
  SpritePosition(this.x, this.y, this.address);
  final int x;

  final int y;

  final int address;
}

class OamSearch implements GpuPhase {
  final AddressSpace _oemRam;

  final MemoryRegisters _registers;

  final List<SpritePosition?> sprites = [];
  final int spriteLength = 10;

  final Lcdc _lcdc;

  int _spritePosIndex = 0;

  _State _state = _State.READING_Y;

  int _spriteY = 0;

  int _spriteX = 0;

  int _i = 0;

  OamSearch(this._oemRam, this._lcdc, this._registers);

  OamSearch start() {
    _spritePosIndex = 0;
    _state = _State.READING_Y;
    _spriteY = 0;
    _spriteX = 0;
    _i = 0;
    for (int j = 0; j < sprites.length; j++) {
      sprites[j] = null;
    }
    return this;
  }

  @override
  bool tick() {
    int spriteAddress = 0xfe00 + 4 * _i;
    switch (_state) {
      case _State.READING_Y:
        _spriteY = _oemRam.getByte(spriteAddress);
        _state = _State.READING_X;
        break;

      case _State.READING_X:
        _spriteX = _oemRam.getByte(spriteAddress + 1);
        if (_spritePosIndex < sprites.length &&
            _between(_spriteY, _registers.get(const GpuRegister.LY()) + 16,
                _spriteY + _lcdc.getSpriteHeight())) {
          sprites[_spritePosIndex++] =
              SpritePosition(_spriteX, _spriteY, spriteAddress);
        }
        _i++;
        _state = _State.READING_Y;
        break;
    }
    return _i < 40;
  }

  static bool _between(int from, int x, int to) {
    return from <= x && x < to;
  }
}
