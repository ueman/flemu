import 'package:gb_emulator/address_space.dart';

class DmaAddressSpace implements AddressSpace {
  final AddressSpace _addressSpace;

  DmaAddressSpace(this._addressSpace);

  @override
  bool accepts(int address) {
    return true;
  }

  @override
  void setByte(int address, int value) {
    throw Exception('Not implemented');
  }

  @override
  int getByte(int address) {
    if (address < 0xe000) {
      return _addressSpace.getByte(address);
    } else {
      return _addressSpace.getByte(address - 0x2000);
    }
  }
}
