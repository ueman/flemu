import 'package:gb_emulator/address_space.dart';

class ShadowAddressSpace implements AddressSpace {
  final AddressSpace _addressSpace;

  final int _echoStart;

  final int _targetStart;

  final int _length;

  ShadowAddressSpace(
      this._addressSpace, this._echoStart, this._targetStart, this._length);

  @override
  bool accepts(int address) {
    return address >= _echoStart && address < _echoStart + _length;
  }

  @override
  void setByte(int address, int value) {
    _addressSpace.setByte(_translate(address), value);
  }

  @override
  int getByte(int address) {
    return _addressSpace.getByte(_translate(address));
  }

  int _translate(int address) {
    return _getRelative(address) + _targetStart;
  }

  int _getRelative(int address) {
    int i = address - _echoStart;
    if (i < 0 || i >= _length) {
      throw Exception('Illegal argument');
    }
    return i;
  }
}
