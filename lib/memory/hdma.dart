import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/gpu/gpu.dart';
import 'package:gb_emulator/memory/ram.dart';

class Hdma implements AddressSpace {
  static const int HDMA1 = 0xff51;

  static const int HDMA2 = 0xff52;

  static const int HDMA3 = 0xff53;

  static const int HDMA4 = 0xff54;

  static const int HDMA5 = 0xff55;

  final AddressSpace _addressSpace;

  final Ram hdma1234 = Ram(HDMA1, 4);

  GpuMode? _gpuMode;

  bool _transferInProgress = false;

  bool _hblankTransfer = false;

  bool _lcdEnabled = false;

  int _length = 0;

  int _src = 0;

  int _dst = 0;

  int _tick = 0;

  Hdma(this._addressSpace);

  @override
  bool accepts(int address) {
    return address >= HDMA1 && address <= HDMA5;
  }

  void tick() {
    if (!isTransferInProgress()) {
      return;
    }
    if (++_tick < 0x20) {
      return;
    }
    for (int j = 0; j < 0x10; j++) {
      _addressSpace.setByte(_dst + j, _addressSpace.getByte(_src + j));
    }
    _src += 0x10;
    _dst += 0x10;
    if (_length-- == 0) {
      _transferInProgress = false;
      _length = 0x7f;
    } else if (_hblankTransfer) {
      _gpuMode = null; // wait until next HBlank
    }
  }

  @override
  void setByte(int address, int value) {
    if (hdma1234.accepts(address)) {
      hdma1234.setByte(address, value);
    } else if (address == HDMA5) {
      if (_transferInProgress && (address & (1 << 7)) == 0) {
        _stopTransfer();
      } else {
        _startTransfer(value);
      }
    }
  }

  @override
  int getByte(int address) {
    if (hdma1234.accepts(address)) {
      return 0xff;
    } else if (address == HDMA5) {
      return (_transferInProgress ? 0 : (1 << 7)) | _length;
    } else {
      throw Exception('IllegalArgument');
    }
  }

  void onGpuUpdate(GpuMode newGpuMode) {
    _gpuMode = newGpuMode;
  }

  void onLcdSwitch(bool lcdEnabled) {
    _lcdEnabled = lcdEnabled;
  }

  bool isTransferInProgress() {
    if (!_transferInProgress) {
      return false;
    } else if (_hblankTransfer &&
        (_gpuMode == GpuMode.HBlank || !_lcdEnabled)) {
      return true;
    } else if (!_hblankTransfer) {
      return true;
    } else {
      return false;
    }
  }

  void _startTransfer(int reg) {
    _hblankTransfer = (reg & (1 << 7)) != 0;
    _length = reg & 0x7f;

    _src = (hdma1234.getByte(HDMA1) << 8) | (hdma1234.getByte(HDMA2) & 0xf0);
    _dst = ((hdma1234.getByte(HDMA3) & 0x1f) << 8) |
        (hdma1234.getByte(HDMA4) & 0xf0);
    _src = _src & 0xfff0;
    _dst = (_dst & 0x1fff) | 0x8000;

    _transferInProgress = true;
  }

  void _stopTransfer() {
    _transferInProgress = false;
  }
}
