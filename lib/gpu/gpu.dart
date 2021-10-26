import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/cpu/interrupt_manager.dart';
import 'package:gb_emulator/gpu/color_palette.dart';
import 'package:gb_emulator/gpu/display.dart';
import 'package:gb_emulator/gpu/gpu_register.dart';
import 'package:gb_emulator/gpu/lcdc.dart';
import 'package:gb_emulator/gpu/phase/gpu_phase.dart';
import 'package:gb_emulator/gpu/phase/h_blank_phase.dart';
import 'package:gb_emulator/gpu/phase/oam_search.dart';
import 'package:gb_emulator/gpu/phase/pixel_transfer.dart';
import 'package:gb_emulator/gpu/phase/v_blank_phase.dart';
import 'package:gb_emulator/memory/dma.dart';
import 'package:gb_emulator/memory/memory_registers.dart';
import 'package:gb_emulator/memory/ram.dart';

enum GpuMode {
  HBlank,
  VBlank,
  OamSearch,
  PixelTransfer,
}

class Gpu implements AddressSpace {
  MemoryRegisters get registers => _r;

  GpuMode getMode() {
    return _mode;
  }

  final AddressSpace _videoRam0 = Ram(0x8000, 0x2000);

  late final AddressSpace? _videoRam1;

  final AddressSpace _oamRam;

  final Display _display;

  final InterruptManager _interruptManager;

  final Dma _dma;

  final Lcdc lcdc = Lcdc();

  final bool gbc;

  final ColorPalette _bgPalette = ColorPalette(0xff68);

  final ColorPalette _oamPalette = ColorPalette(0xff6a);

  final HBlankPhase _hBlankPhase = HBlankPhase();

  late final OamSearch _oamSearchPhase = OamSearch(_oamRam, lcdc, _r);

  late final PixelTransfer _pixelTransferPhase = PixelTransfer(_videoRam0,
      _videoRam1, _oamRam, _display, lcdc, _r, gbc, _bgPalette, _oamPalette);

  final VBlankPhase _vBlankPhase = VBlankPhase();

  bool lcdEnabled = true;

  int _lcdEnabledDelay = 0;

  MemoryRegisters _r = MemoryRegisters(GpuRegister.values);

  int _ticksInLine = 0;

  late GpuMode _mode;

  late GpuPhase _phase;

  Gpu(this._display, this._interruptManager, this._dma, this._oamRam,
      this.gbc) {
    if (gbc) {
      _videoRam1 = Ram(0x8000, 0x2000);
    }
    _oamPalette.fillWithFF();

    _mode = GpuMode.OamSearch;
    _phase = _oamSearchPhase.start();
  }

  AddressSpace? _getAddressSpace(int address) {
    if (_videoRam0.accepts(address) /* && mode != Mode.PixelTransfer*/) {
      return _getVideoRam();
    } else if (_oamRam.accepts(address) &&
        !_dma
            .isOamBlocked() /* && mode != Mode.OamSearch && mode != Mode.PixelTransfer*/) {
      return _oamRam;
    } else if (lcdc.accepts(address)) {
      return lcdc;
    } else if (_r.accepts(address)) {
      return _r;
    } else if (gbc && _bgPalette.accepts(address)) {
      return _bgPalette;
    } else if (gbc && _oamPalette.accepts(address)) {
      return _oamPalette;
    } else {
      return null;
    }
  }

  AddressSpace? _getVideoRam() {
    if (gbc && (_r.get(const GpuRegister.VBK()) & 1) == 1) {
      return _videoRam1;
    } else {
      return _videoRam0;
    }
  }

  AddressSpace getVideoRam0() {
    return _videoRam0;
  }

  AddressSpace? getVideoRam1() {
    return _videoRam1;
  }

  @override
  bool accepts(int address) {
    return _getAddressSpace(address) != null;
  }

  @override
  void setByte(int address, int value) {
    if (address == const GpuRegister.STAT().getAddress()) {
      _setStat(value);
    } else {
      AddressSpace? space = _getAddressSpace(address);
      if (space == lcdc) {
        _setLcdc(value);
      } else if (space != null) {
        space.setByte(address, value);
      }
    }
  }

  @override
  int getByte(int address) {
    if (address == const GpuRegister.STAT().getAddress()) {
      return _getStat();
    } else {
      AddressSpace? space = _getAddressSpace(address);
      if (space == null) {
        return 0xff;
      } else if (address == const GpuRegister.VBK().getAddress()) {
        return gbc ? 0xfe : 0xff;
      } else {
        return space.getByte(address);
      }
    }
  }

  GpuMode? tick() {
    if (!lcdEnabled) {
      if (_lcdEnabledDelay != -1) {
        if (--_lcdEnabledDelay == 0) {
          _display.enableLcd();
          lcdEnabled = true;
        }
      }
    }
    if (!lcdEnabled) {
      return null;
    }

    GpuMode oldMode = _mode;
    _ticksInLine++;
    if (_phase.tick()) {
      // switch line 153 to 0
      if (_ticksInLine == 4 &&
          _mode == GpuMode.VBlank &&
          _r.get(const GpuRegister.LY()) == 153) {
        _r.put(const GpuRegister.LY(), 0);
        _requestLycEqualsLyInterrupt();
      }
    } else {
      switch (oldMode) {
        case GpuMode.OamSearch:
          _mode = GpuMode.PixelTransfer;
          _phase = _pixelTransferPhase.start(_oamSearchPhase.sprites);
          break;

        case GpuMode.PixelTransfer:
          _mode = GpuMode.HBlank;
          _phase = _hBlankPhase.start(_ticksInLine);
          _requestLcdcInterrupt(3);
          break;

        case GpuMode.HBlank:
          _ticksInLine = 0;
          if (_r.preIncrement(const GpuRegister.LY()) == 144) {
            _mode = GpuMode.VBlank;
            _phase = _vBlankPhase.start();
            _interruptManager.requestInterrupt(const InterruptType.vBlank());
            _requestLcdcInterrupt(4);
          } else {
            _mode = GpuMode.OamSearch;
            _phase = _oamSearchPhase.start();
          }
          _requestLcdcInterrupt(5);
          _requestLycEqualsLyInterrupt();
          break;

        case GpuMode.VBlank:
          _ticksInLine = 0;
          if (_r.preIncrement(const GpuRegister.LY()) == 1) {
            _mode = GpuMode.OamSearch;
            _r.put(const GpuRegister.LY(), 0);
            _phase = _oamSearchPhase.start();
            _requestLcdcInterrupt(5);
          } else {
            _phase = _vBlankPhase.start();
          }
          _requestLycEqualsLyInterrupt();
          break;
      }
    }
    if (oldMode == _mode) {
      return null;
    } else {
      return _mode;
    }
  }

  int getTicksInLine() {
    return _ticksInLine;
  }

  void _requestLcdcInterrupt(int statBit) {
    if ((_r.get(const GpuRegister.STAT()) & (1 << statBit)) != 0) {
      _interruptManager.requestInterrupt(const InterruptType.lcdc());
    }
  }

  void _requestLycEqualsLyInterrupt() {
    if (_r.get(const GpuRegister.LYC()) == _r.get(const GpuRegister.LY())) {
      _requestLcdcInterrupt(6);
    }
  }

  int _getStat() {
    return _r.get(const GpuRegister.STAT()) |
        _mode.index |
        (_r.get(const GpuRegister.LYC()) == _r.get(const GpuRegister.LY())
            ? (1 << 2)
            : 0) |
        0x80;
  }

  void _setStat(int value) {
    _r.put(const GpuRegister.STAT(),
        value & 248 /* 0b11111000 */); // last three bits are read-only
  }

  void _setLcdc(int value) {
    lcdc.set(value);
    if ((value & (1 << 7)) == 0) {
      _disableLcd();
    } else {
      _enableLcd();
    }
  }

  void _disableLcd() {
    _r.put(const GpuRegister.LY(), 0);
    _ticksInLine = 0;
    _phase = _hBlankPhase.start(250);
    _mode = GpuMode.HBlank;
    lcdEnabled = false;
    _lcdEnabledDelay = -1;
    _display.disableLcd();
  }

  void _enableLcd() {
    _lcdEnabledDelay = 244;
  }
}
