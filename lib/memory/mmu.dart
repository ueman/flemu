import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/cpu/bit_utils.dart';
import 'package:gb_emulator/int_x.dart';

class Mmu implements AddressSpace {
  // private static final Logger LOG = LoggerFactory.getLogger(Mmu.class);

  final List<AddressSpace> _spaces = [];

  void addAddressSpace(AddressSpace space) {
    _spaces.add(space);
  }

  @override
  bool accepts(int address) {
    return true;
  }

  @override
  void setByte(int address, int value) {
    assertIsByte("value", value);
    assertIsWordArgument("address", address);
    _getSpace(address).setByte(address, value);
  }

  @override
  int getByte(int address) {
    assertIsWordArgument("address", address);
    return _getSpace(address).getByte(address);
  }

  AddressSpace _getSpace(int address) {
    for (AddressSpace s in _spaces) {
      if (s.accepts(address)) {
        return s;
      }
    }
    return _VoidAddressSpace();
  }
}

class _VoidAddressSpace extends AddressSpace {
  @override
  bool accepts(int address) {
    return true;
  }

  @override
  void setByte(int address, int value) {
    if (address < 0 || address > 0xffff) {
      throw Exception("Invalid address: ${address.toHex()}");
    }
    //LOG.debug(
    //    "Writing value ${value.toHex()} to void address ${address.toHex()}");
  }

  @override
  int getByte(int address) {
    if (address < 0 || address > 0xffff) {
      throw Exception("Invalid address: ${address.toHex()}");
    }
    //LOG.debug(
    //    "Reading value from void address {}", Integer.toHexString(address));
    return 0xff;
  }
}
