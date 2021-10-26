import 'package:flutter/rendering.dart';
import 'package:gb_emulator/cpu/bit_utils.dart';
import 'package:gb_emulator/cpu/flags.dart';
import 'package:gb_emulator/cpu/op/data_type.dart';

class _FunctionKey {
  _FunctionKey(this.name, this.type1, [this.type2]);

  final String name;
  final DataType type1;
  final DataType? type2;

  @override
  operator ==(o) =>
      o is _FunctionKey &&
      o.name == name &&
      o.type1 == type1 &&
      o.type2 == type2;

  @override
  int get hashCode => hashValues(name, type1, type2);
}

typedef IntRegistryFunction = int Function(Flags flags, int arg);
typedef BiIntRegistryFunction = int Function(Flags flags, int arg1, int arg2);

class AluFunctions {
  final Map<_FunctionKey, IntRegistryFunction> _functions = {};

  final Map<_FunctionKey, BiIntRegistryFunction> _biFunctions = {};

  IntRegistryFunction? findIntAluFunction(String name, DataType argumentType) {
    return _functions[_FunctionKey(name, argumentType)];
  }

  BiIntRegistryFunction? findBiAluFunction(
    String name,
    DataType arg1Type,
    DataType arg2Type,
  ) {
    return _biFunctions[_FunctionKey(name, arg1Type, arg2Type)];
  }

  void registerIntAluFunction(
      String name, DataType dataType, IntRegistryFunction function) {
    _functions[_FunctionKey(name, dataType)] = function;
  }

  void registerBiAluFunction(String name, DataType dataType1,
      DataType dataType2, BiIntRegistryFunction function) {
    _biFunctions[_FunctionKey(name, dataType1, dataType2)] = function;
  }

  AluFunctions() {
    registerIntAluFunction("INC", DataType.d8, (flags, arg) {
      int result = (arg + 1) & 0xff;
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH((arg & 0x0f) == 0x0f);
      return result;
    });
    registerIntAluFunction(
        "INC", DataType.d16, (flags, arg) => (arg + 1) & 0xffff);
    registerIntAluFunction("DEC", DataType.d8, (flags, arg) {
      int result = (arg - 1) & 0xff;
      flags.setZ(result == 0);
      flags.setN(true);
      flags.setH((arg & 0x0f) == 0x0);
      return result;
    });
    registerIntAluFunction(
        "DEC", DataType.d16, (flags, arg) => (arg - 1) & 0xffff);
    registerBiAluFunction("ADD", DataType.d16, DataType.d16,
        (flags, arg1, arg2) {
      flags.setN(false);
      flags.setH((arg1 & 0x0fff) + (arg2 & 0x0fff) > 0x0fff);
      flags.setC(arg1 + arg2 > 0xffff);
      return (arg1 + arg2) & 0xffff;
    });
    registerBiAluFunction("ADD", DataType.d16, DataType.r8,
        (flags, arg1, arg2) => (arg1 + arg2) & 0xffff);
    registerBiAluFunction("ADD_SP", DataType.d16, DataType.r8,
        (flags, arg1, arg2) {
      flags.setZ(false);
      flags.setN(false);

      int result = arg1 + arg2;
      flags.setC((((arg1 & 0xff) + (arg2 & 0xff)) & 0x100) != 0);
      flags.setH((((arg1 & 0x0f) + (arg2 & 0x0f)) & 0x10) != 0);
      return result & 0xffff;
    });
    registerIntAluFunction("DAA", DataType.d8, (flags, arg) {
      int result = arg;
      if (flags.isN()) {
        if (flags.isH()) {
          result = (result - 6) & 0xff;
        }
        if (flags.isC()) {
          result = (result - 0x60) & 0xff;
        }
      } else {
        if (flags.isH() || (result & 0xf) > 9) {
          result += 0x06;
        }
        if (flags.isC() || result > 0x9f) {
          result += 0x60;
        }
      }
      flags.setH(false);
      if (result > 0xff) {
        flags.setC(true);
      }
      result &= 0xff;
      flags.setZ(result == 0);
      return result;
    });
    registerIntAluFunction("CPL", DataType.d8, (flags, arg) {
      flags.setN(true);
      flags.setH(true);
      return (~arg) & 0xff;
    });
    registerIntAluFunction("SCF", DataType.d8, (flags, arg) {
      flags.setN(false);
      flags.setH(false);
      flags.setC(true);
      return arg;
    });
    registerIntAluFunction("CCF", DataType.d8, (flags, arg) {
      flags.setN(false);
      flags.setH(false);
      flags.setC(!flags.isC());
      return arg;
    });
    registerBiAluFunction("ADD", DataType.d8, DataType.d8,
        (flags, byte1, byte2) {
      flags.setZ(((byte1 + byte2) & 0xff) == 0);
      flags.setN(false);
      flags.setH((byte1 & 0x0f) + (byte2 & 0x0f) > 0x0f);
      flags.setC(byte1 + byte2 > 0xff);
      return (byte1 + byte2) & 0xff;
    });
    registerBiAluFunction("ADC", DataType.d8, DataType.d8,
        (flags, byte1, byte2) {
      int carry = flags.isC() ? 1 : 0;
      flags.setZ(((byte1 + byte2 + carry) & 0xff) == 0);
      flags.setN(false);
      flags.setH((byte1 & 0x0f) + (byte2 & 0x0f) + carry > 0x0f);
      flags.setC(byte1 + byte2 + carry > 0xff);
      return (byte1 + byte2 + carry) & 0xff;
    });
    registerBiAluFunction("SUB", DataType.d8, DataType.d8,
        (flags, byte1, byte2) {
      flags.setZ(((byte1 - byte2) & 0xff) == 0);
      flags.setN(true);
      flags.setH((0x0f & byte2) > (0x0f & byte1));
      flags.setC(byte2 > byte1);
      return (byte1 - byte2) & 0xff;
    });
    registerBiAluFunction("SBC", DataType.d8, DataType.d8,
        (flags, byte1, byte2) {
      int carry = flags.isC() ? 1 : 0;
      int res = byte1 - byte2 - carry;

      flags.setZ((res & 0xff) == 0);
      flags.setN(true);
      flags.setH(((byte1 ^ byte2 ^ (res & 0xff)) & (1 << 4)) != 0);
      flags.setC(res < 0);
      return res & 0xff;
    });
    registerBiAluFunction("AND", DataType.d8, DataType.d8,
        (flags, byte1, byte2) {
      int result = byte1 & byte2;
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(true);
      flags.setC(false);
      return result;
    });
    registerBiAluFunction("OR", DataType.d8, DataType.d8,
        (flags, byte1, byte2) {
      int result = byte1 | byte2;
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(false);
      flags.setC(false);
      return result;
    });
    registerBiAluFunction("XOR", DataType.d8, DataType.d8,
        (flags, byte1, byte2) {
      int result = (byte1 ^ byte2) & 0xff;
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(false);
      flags.setC(false);
      return result;
    });
    registerBiAluFunction("CP", DataType.d8, DataType.d8,
        (flags, byte1, byte2) {
      flags.setZ(((byte1 - byte2) & 0xff) == 0);
      flags.setN(true);
      flags.setH((0x0f & byte2) > (0x0f & byte1));
      flags.setC(byte2 > byte1);
      return byte1;
    });
    registerIntAluFunction("RLC", DataType.d8, (flags, arg) {
      int result = (arg << 1) & 0xff;
      if ((arg & (1 << 7)) != 0) {
        result |= 1;
        flags.setC(true);
      } else {
        flags.setC(false);
      }
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(false);
      return result;
    });
    registerIntAluFunction("RRC", DataType.d8, (flags, arg) {
      int result = arg >> 1;
      if ((arg & 1) == 1) {
        result |= (1 << 7);
        flags.setC(true);
      } else {
        flags.setC(false);
      }
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(false);
      return result;
    });
    registerIntAluFunction("RL", DataType.d8, (flags, arg) {
      int result = (arg << 1) & 0xff;
      result |= flags.isC() ? 1 : 0;
      flags.setC((arg & (1 << 7)) != 0);
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(false);
      return result;
    });
    registerIntAluFunction("RR", DataType.d8, (flags, arg) {
      int result = arg >> 1;
      result |= flags.isC() ? (1 << 7) : 0;
      flags.setC((arg & 1) != 0);
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(false);
      return result;
    });
    registerIntAluFunction("SLA", DataType.d8, (flags, arg) {
      int result = (arg << 1) & 0xff;
      flags.setC((arg & (1 << 7)) != 0);
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(false);
      return result;
    });
    registerIntAluFunction("SRA", DataType.d8, (flags, arg) {
      int result = (arg >> 1) | (arg & (1 << 7));
      flags.setC((arg & 1) != 0);
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(false);
      return result;
    });
    registerIntAluFunction("SWAP", DataType.d8, (flags, arg) {
      int upper = arg & 0xf0;
      int lower = arg & 0x0f;
      int result = (lower << 4) | (upper >> 4);
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(false);
      flags.setC(false);
      return result;
    });
    registerIntAluFunction("SRL", DataType.d8, (flags, arg) {
      int result = (arg >> 1);
      flags.setC((arg & 1) != 0);
      flags.setZ(result == 0);
      flags.setN(false);
      flags.setH(false);
      return result;
    });
    registerBiAluFunction("BIT", DataType.d8, DataType.d8, (flags, arg1, arg2) {
      int bit = arg2;
      flags.setN(false);
      flags.setH(true);
      if (bit < 8) {
        flags.setZ(!getBit(arg1, arg2));
      }
      return arg1;
    });
    registerBiAluFunction("RES", DataType.d8, DataType.d8,
        (flags, arg1, arg2) => clearBit(arg1, arg2));
    registerBiAluFunction("SET", DataType.d8, DataType.d8,
        (flags, arg1, arg2) => setBit(arg1, arg2));
  }
}
