import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/gpu/color_palette.dart';
import 'package:gb_emulator/gpu/color_pixel_fifo.dart';
import 'package:gb_emulator/gpu/display.dart';
import 'package:gb_emulator/gpu/dmg_pixel_fifo.dart';
import 'package:gb_emulator/gpu/fetcher.dart';
import 'package:gb_emulator/gpu/gpu_register.dart';
import 'package:gb_emulator/gpu/lcdc.dart';
import 'package:gb_emulator/gpu/phase/gpu_phase.dart';
import 'package:gb_emulator/gpu/phase/oam_search.dart';
import 'package:gb_emulator/gpu/pixel_fifo.dart';
import 'package:gb_emulator/memory/memory_registers.dart';

class PixelTransfer implements GpuPhase {
  late final PixelFifo _fifo;

  late final Fetcher _fetcher;

  final Display _display;

  final MemoryRegisters _r;

  final Lcdc _lcdc;

  final bool _gbc;

  List<SpritePosition?> _sprites = [];

  int _droppedPixels = 0;

  int _x = 0;

  bool _window = false;

  PixelTransfer(
    AddressSpace videoRam0,
    AddressSpace? videoRam1,
    AddressSpace oemRam,
    this._display,
    this._lcdc,
    this._r,
    this._gbc,
    ColorPalette bgPalette,
    ColorPalette oamPalette,
  ) {
    if (_gbc) {
      _fifo = ColorPixelFifo(_lcdc, _display, bgPalette, oamPalette);
    } else {
      _fifo = DmgPixelFifo(_display, _lcdc, _r);
    }
    _fetcher = Fetcher(_fifo, videoRam0, videoRam1, oemRam, _lcdc, _r, _gbc);
  }

  PixelTransfer start(List<SpritePosition?> sprites) {
    _sprites = sprites;
    _droppedPixels = 0;
    _x = 0;
    _window = false;

    _fetcher.init();
    if (_gbc || _lcdc.isBgAndWindowDisplay()) {
      _startFetchingBackground();
    } else {
      _fetcher.fetchingDisabled();
    }
    return this;
  }

  @override
  bool tick() {
    _fetcher.tick();
    if (_lcdc.isBgAndWindowDisplay() || _gbc) {
      if (_fifo.getLength() <= 8) {
        return true;
      }
      if (_droppedPixels < _r.get(const GpuRegister.SCX()) % 8) {
        _fifo.dropPixel();
        _droppedPixels++;
        return true;
      }
      if (!_window &&
          _lcdc.isWindowDisplay() &&
          _r.get(const GpuRegister.LY()) >= _r.get(const GpuRegister.WY()) &&
          _x == _r.get(const GpuRegister.WX()) - 7) {
        _window = true;
        _startFetchingWindow();
        return true;
      }
    }

    if (_lcdc.isObjDisplay()) {
      if (_fetcher.spriteInProgress()) {
        return true;
      }
      var spriteAdded = false;
      for (int i = 0; i < _sprites.length; i++) {
        var s = _sprites[i];
        if (s == null) {
          continue;
        }
        if (_x == 0 && s.x < 8) {
          if (!spriteAdded) {
            _fetcher.addSprite(s, 8 - s.x, i);
            spriteAdded = true;
          }
          _sprites[i] = null;
        } else if (s.x - 8 == _x) {
          if (!spriteAdded) {
            _fetcher.addSprite(s, 0, i);
            spriteAdded = true;
          }
          _sprites[i] = null;
        }
        if (spriteAdded) {
          return true;
        }
      }
    }

    _fifo.putPixelToScreen();
    if (++_x == 160) {
      return false;
    }
    return true;
  }

  void _startFetchingBackground() {
    int bgX = _r.get(const GpuRegister.SCX()) ~/ 0x08;
    int bgY =
        (_r.get(const GpuRegister.SCY()) + _r.get(const GpuRegister.LY())) %
            0x100;

    _fetcher.startFetching(
        _lcdc.getBgTileMapDisplay() + (bgY ~/ 0x08) * 0x20,
        _lcdc.getBgWindowTileData(),
        bgX,
        _lcdc.isBgWindowTileDataSigned(),
        bgY % 0x08);
  }

  void _startFetchingWindow() {
    int winX = (_x - _r.get(const GpuRegister.WX()) + 7) ~/ 0x08;
    int winY = _r.get(const GpuRegister.LY()) - _r.get(const GpuRegister.WY());

    _fetcher.startFetching(
        _lcdc.getWindowTileMapDisplay() + (winY ~/ 0x08) * 0x20,
        _lcdc.getBgWindowTileData(),
        winX,
        _lcdc.isBgWindowTileDataSigned(),
        winY % 0x08);
  }
}
