import 'package:gb_emulator/address_space.dart';

abstract class Register {
  int getAddress();

  RegisterType getType();
}

class RegisterType {
  const RegisterType.r()
      : allowsRead = true,
        allowsWrite = false;
  const RegisterType.w()
      : allowsRead = false,
        allowsWrite = true;
  const RegisterType.rw()
      : allowsRead = true,
        allowsWrite = true;

  final bool allowsRead;

  final bool allowsWrite;
}

class MemoryRegisters implements AddressSpace {
  Map<int, Register> _registers = {};

  Map<int, int> _values = {};

  MemoryRegisters(List<Register> registers) {
    Map<int, Register> map = {};
    for (Register r in registers) {
      if (map.containsKey(r.getAddress())) {
        throw Exception(
            "Two registers with the same address: ${r.getAddress()}");
      }
      map[r.getAddress()] = r;
      _values[r.getAddress()] = 0;
    }
    _registers = Map.unmodifiable(map);
  }

  MemoryRegisters.copy(MemoryRegisters original) {
    _registers = original._registers;
    _values = Map.unmodifiable(original._values);
  }

  int get(Register reg) {
    if (_registers.containsKey(reg.getAddress())) {
      return _values[reg.getAddress()]!;
    } else {
      throw Exception("Not valid register: $reg");
    }
  }

  void put(Register reg, int value) {
    if (_registers.containsKey(reg.getAddress())) {
      _values[reg.getAddress()] = value;
    } else {
      throw Exception("Not valid register: $reg");
    }
  }

  MemoryRegisters freeze() {
    return MemoryRegisters.copy(this);
  }

  int preIncrement(Register reg) {
    if (_registers.containsKey(reg.getAddress())) {
      int value = _values[reg.getAddress()]! + 1;
      _values[reg.getAddress()] = value;
      return value;
    } else {
      throw Exception("Not valid register: $reg");
    }
  }

  @override
  bool accepts(int address) {
    return _registers.containsKey(address);
  }

  @override
  void setByte(int address, int value) {
    if (_registers[address]!.getType().allowsWrite) {
      _values[address] = value;
    }
  }

  @override
  int getByte(int address) {
    if (_registers[address]!.getType().allowsRead) {
      return _values[address]!;
    } else {
      return 0xff;
    }
  }
}
