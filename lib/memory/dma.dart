import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/cpu/speed_mode.dart';
import 'package:gb_emulator/memory/dma_address_space.dart';

class Dma implements AddressSpace {
  late final AddressSpace _addressSpace;

  final AddressSpace _oam;

  final SpeedMode _speedMode;

  bool _transferInProgress = false;

  bool _restarted = false;

  int _from = 0;

  int _ticks = 0;

  int _regValue = 0xff;

  Dma(AddressSpace addressSpace, this._oam, this._speedMode) {
    _addressSpace = DmaAddressSpace(addressSpace);
  }

  @override
  bool accepts(int address) {
    return address == 0xff46;
  }

  void tick() {
    if (_transferInProgress) {
      if (++_ticks >= 648 / _speedMode.getSpeedMode()) {
        _transferInProgress = false;
        _restarted = false;
        _ticks = 0;
        for (int i = 0; i < 0xa0; i++) {
          _oam.setByte(0xfe00 + i, _addressSpace.getByte(_from + i));
        }
      }
    }
  }

  @override
  void setByte(int address, int value) {
    _from = value * 0x100;
    _restarted = isOamBlocked();
    _ticks = 0;
    _transferInProgress = true;
    _regValue = value;
  }

  @override
  int getByte(int address) {
    return _regValue;
  }

  bool isOamBlocked() {
    return _restarted || (_transferInProgress && _ticks >= 5);
  }
}
