import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/cpu/bit_utils.dart';
import 'package:gb_emulator/gpu/gpu_register.dart';
import 'package:gb_emulator/gpu/lcdc.dart';
import 'package:gb_emulator/gpu/phase/oam_search.dart';
import 'package:gb_emulator/gpu/pixel_fifo.dart';
import 'package:gb_emulator/gpu/tile_attributes.dart';
import 'package:gb_emulator/memory/memory_registers.dart';

enum _State {
  READ_TILE_ID,
  READ_DATA_1,
  READ_DATA_2,
  PUSH,
  READ_SPRITE_TILE_ID,
  READ_SPRITE_FLAGS,
  READ_SPRITE_DATA_1,
  READ_SPRITE_DATA_2,
  PUSH_SPRITE,
}

class Fetcher {
  static final List<int> emptyPixelLine = [0, 0, 0, 0, 0, 0, 0, 0];

  Fetcher(
    this._fifo,
    this._videoRam0,
    this._videoRam1,
    this._oemRam,
    this._lcdc,
    this._r,
    this._gbc,
  );

  final PixelFifo _fifo;

  final AddressSpace _videoRam0;

  final AddressSpace? _videoRam1;

  final AddressSpace _oemRam;

  final MemoryRegisters _r;

  final Lcdc _lcdc;

  final bool _gbc;

  final List<int> _pixelLine = [0, 0, 0, 0, 0, 0, 0, 0];

  late _State state;

  bool _fetchingDisabled = false;

  int _mapAddress = 0;

  int _xOffset = 0;

  int _tileDataAddress = 0;

  bool _tileIdSigned = false;

  int _tileLine = 0;

  int _tileId = 0;

  late TileAttributes _tileAttributes;

  int _tileData1 = 0;

  int _tileData2 = 0;

  int _spriteTileLine = 0;

  late SpritePosition _sprite;

  late TileAttributes _spriteAttributes;

  int _spriteOffset = 0;

  int _spriteOamIndex = 0;

  int _divider = 2;

  void init() {
    state = _State.READ_TILE_ID;
    _tileId = 0;
    _tileData1 = 0;
    _tileData2 = 0;
    _divider = 2;
    _fetchingDisabled = false;
  }

  void startFetching(
    int mapAddress,
    int tileDataAddress,
    int xOffset,
    bool tileIdSigned,
    int tileLine,
  ) {
    _mapAddress = mapAddress;
    _tileDataAddress = tileDataAddress;
    _xOffset = xOffset;
    _tileIdSigned = tileIdSigned;
    _tileLine = tileLine;
    _fifo.clear();

    state = _State.READ_TILE_ID;
    _tileId = 0;
    _tileData1 = 0;
    _tileData2 = 0;
    _divider = 2;
  }

  void fetchingDisabled() {
    _fetchingDisabled = true;
  }

  void addSprite(SpritePosition sprite, int offset, int oamIndex) {
    sprite = sprite;
    state = _State.READ_SPRITE_TILE_ID;
    _spriteTileLine = _r.get(const GpuRegister.LY()) + 16 - sprite.y;
    _spriteOffset = offset;
    _spriteOamIndex = oamIndex;
  }

  void tick() {
    if (_fetchingDisabled && state == _State.READ_TILE_ID) {
      if (_fifo.getLength() <= 8) {
        _fifo.enqueue8Pixels(emptyPixelLine, _tileAttributes);
      }
      return;
    }

    if (--_divider == 0) {
      _divider = 2;
    } else {
      return;
    }

    switch (state) {
      case _State.READ_TILE_ID:
        _tileId = _videoRam0.getByte(_mapAddress + _xOffset);
        if (_gbc) {
          _tileAttributes = TileAttributes.valueOf(
            _videoRam1!.getByte(_mapAddress + _xOffset),
          );
        } else {
          _tileAttributes = TileAttributes.empty;
        }
        state = _State.READ_DATA_1;
        break;

      case _State.READ_DATA_1:
        _tileData1 = _getTileData(_tileId, _tileLine, 0, _tileDataAddress,
            _tileIdSigned, _tileAttributes, 8);
        state = _State.READ_DATA_2;
        break;

      case _State.READ_DATA_2:
        _tileData2 = _getTileData(_tileId, _tileLine, 1, _tileDataAddress,
            _tileIdSigned, _tileAttributes, 8);
        state = _State.PUSH;
        continue statePush;

      statePush:
      case _State.PUSH:
        if (_fifo.getLength() <= 8) {
          _fifo.enqueue8Pixels(
              zip(_tileData1, _tileData2, _tileAttributes.isXflip()),
              _tileAttributes);
          _xOffset = (_xOffset + 1) % 0x20;
          state = _State.READ_TILE_ID;
        }
        break;

      case _State.READ_SPRITE_TILE_ID:
        _tileId = _oemRam.getByte(_sprite.address + 2);
        state = _State.READ_SPRITE_FLAGS;
        break;

      case _State.READ_SPRITE_FLAGS:
        _spriteAttributes =
            TileAttributes.valueOf(_oemRam.getByte(_sprite.address + 3));
        state = _State.READ_SPRITE_DATA_1;
        break;

      case _State.READ_SPRITE_DATA_1:
        if (_lcdc.getSpriteHeight() == 16) {
          _tileId &= 0xfe;
        }
        _tileData1 = _getTileData(_tileId, _spriteTileLine, 0, 0x8000, false,
            _spriteAttributes, _lcdc.getSpriteHeight());
        state = _State.READ_SPRITE_DATA_2;
        break;

      case _State.READ_SPRITE_DATA_2:
        _tileData2 = _getTileData(_tileId, _spriteTileLine, 1, 0x8000, false,
            _spriteAttributes, _lcdc.getSpriteHeight());
        state = _State.PUSH_SPRITE;
        break;

      case _State.PUSH_SPRITE:
        _fifo.setOverlay(
            zip(_tileData1, _tileData2, _spriteAttributes.isXflip()),
            _spriteOffset,
            _spriteAttributes,
            _spriteOamIndex);
        state = _State.READ_TILE_ID;
        break;
    }
  }

  int _getTileData(int tileId, int line, int byteNumber, int tileDataAddress,
      bool signed, TileAttributes attr, int tileHeight) {
    int effectiveLine;
    if (attr.isYflip()) {
      effectiveLine = tileHeight - 1 - line;
    } else {
      effectiveLine = line;
    }

    int tileAddress;
    if (signed) {
      tileAddress = tileDataAddress + toSigned(tileId) * 0x10;
    } else {
      tileAddress = tileDataAddress + tileId * 0x10;
    }
    AddressSpace videoRam =
        ((attr.getBank() == 0 || !_gbc) ? _videoRam0 : _videoRam1)!;
    return videoRam.getByte(tileAddress + effectiveLine * 2 + byteNumber);
  }

  bool spriteInProgress() {
    return {
      _State.READ_SPRITE_TILE_ID,
      _State.READ_SPRITE_FLAGS,
      _State.READ_SPRITE_DATA_1,
      _State.READ_SPRITE_DATA_2,
      _State.PUSH_SPRITE,
    }.contains(state);
  }

  List<int> zip(
    int data1,
    int data2,
    bool reverse, [
    List<int>? pixelLine,
  ]) {
    pixelLine = pixelLine ?? _pixelLine;
    for (int i = 7; i >= 0; i--) {
      int mask = (1 << i);
      int p = 2 * ((data2 & mask) == 0 ? 0 : 1) + ((data1 & mask) == 0 ? 0 : 1);
      if (reverse) {
        pixelLine[i] = p;
      } else {
        pixelLine[7 - i] = p;
      }
    }
    return pixelLine;
  }
}
