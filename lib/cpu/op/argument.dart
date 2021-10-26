import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/cpu/bit_utils.dart';
import 'package:gb_emulator/cpu/op/data_type.dart';
import 'package:gb_emulator/cpu/registers.dart';

class _A extends Argument {
  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.a;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.a = value;
  }

  @override
  String get label => 'A';
}

class _B extends Argument {
  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.b;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.b = value;
  }

  @override
  String get label => 'B';
}

class _C extends Argument {
  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.c;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.c = value;
  }

  @override
  String get label => 'C';
}

class _D extends Argument {
  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.d;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.d = value;
  }

  @override
  String get label => 'D';
}

class _E extends Argument {
  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.e;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.e = value;
  }

  @override
  String get label => 'E';
}

class _H extends Argument {
  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.h;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.h = value;
  }

  @override
  String get label => 'H';
}

class _L extends Argument {
  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.l;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.l = value;
  }

  @override
  String get label => 'L';
}

class _AF extends Argument {
  _AF() : super.withArgs(0, false, DataType.D16);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.af;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.af = value;
  }

  @override
  String get label => 'AF';
}

class _BC extends Argument {
  _BC() : super.withArgs(0, false, DataType.D16);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.bc;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.bc = value;
  }

  @override
  String get label => 'BC';
}

class _DE extends Argument {
  _DE() : super.withArgs(0, false, DataType.D16);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.de;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.de = value;
  }

  @override
  String get label => 'DE';
}

class _HL extends Argument {
  _HL() : super.withArgs(0, false, DataType.D16);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.hl;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.hl = value;
  }

  @override
  String get label => 'HL';
}

class _SP extends Argument {
  _SP() : super.withArgs(0, false, DataType.D16);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.sp;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.sp = value;
  }

  @override
  String get label => 'SP';
}

class _PC extends Argument {
  _PC() : super.withArgs(0, false, DataType.D16);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return registers.pc;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    registers.pc = value;
  }

  @override
  String get label => 'PC';
}

class _D8 extends Argument {
  _D8() : super.withArgs(1, false, DataType.D8);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return args.first;
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    throw Exception('Not supported');
  }

  @override
  String get label => 'd8';
}

class _D16 extends Argument {
  _D16() : super.withArgs(2, false, DataType.D16);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return toWordFromList(args);
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    throw Exception('Not supported');
  }

  @override
  String get label => 'd16';
}

class _R8 extends Argument {
  _R8() : super.withArgs(1, false, DataType.R8);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return toSigned(args.first);
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    throw Exception('Not supported');
  }

  @override
  String get label => 'r8';
}

class _A16 extends Argument {
  _A16() : super.withArgs(2, false, DataType.D16);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return toWordFromList(args);
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    throw Exception('Not supported');
  }

  @override
  String get label => 'a16';
}

class __BC extends Argument {
  __BC() : super.withArgs(0, true, DataType.D8);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return addressSpace.getByte(registers.bc);
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    addressSpace.setByte(registers.bc, value);
  }

  @override
  String get label => '(BC)';
}

class __DE extends Argument {
  __DE() : super.withArgs(0, true, DataType.D8);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return addressSpace.getByte(registers.de);
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    addressSpace.setByte(registers.de, value);
  }

  @override
  String get label => '(DE)';
}

class __HL extends Argument {
  __HL() : super.withArgs(0, true, DataType.D8);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return addressSpace.getByte(registers.hl);
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    addressSpace.setByte(registers.hl, value);
  }

  @override
  String get label => '(HL)';
}

class __A8 extends Argument {
  __A8() : super.withArgs(1, true, DataType.D8);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return addressSpace.getByte(0xff00 | args[0]);
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    addressSpace.setByte(0xff00 | args[0], value);
  }

  @override
  String get label => '(a8)';
}

class __A16 extends Argument {
  __A16() : super.withArgs(2, true, DataType.D8);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return addressSpace.getByte(toWordFromList(args));
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    addressSpace.setByte(toWordFromList(args), value);
  }

  @override
  String get label => '(a16)';
}

class __C extends Argument {
  __C() : super.withArgs(0, true, DataType.D8);

  @override
  int read(Registers registers, AddressSpace addressSpace, List<int> args) {
    return addressSpace.getByte(0xff00 | registers.c);
  }

  @override
  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value) {
    addressSpace.setByte(0xff00 | registers.c, value);
  }

  @override
  String get label => '(C)';
}

abstract class Argument {
  String get label;

  final int operandLength;

  final bool memory;

  final DataType dataType;

  Argument()
      : operandLength = 0,
        memory = false,
        dataType = DataType.D8;

  Argument.withArgs(this.operandLength, this.memory, this.dataType);

  static final List<Argument> _arguments = [
    _A(),
    _B(),
    _C(),
    _D(),
    _E(),
    _H(),
    _L(),
    _AF(),
    _BC(),
    _DE(),
    _HL(),
    _SP(),
    _PC(),
    _D8(),
    _D16(),
    _R8(),
    _A16(),
    __BC(),
    __DE(),
    __HL(),
    __A8(),
    __A16(),
    __C(),
  ];

  int read(Registers registers, AddressSpace addressSpace, List<int> args);

  void write(Registers registers, AddressSpace addressSpace, List<int> args,
      int value);

  factory Argument.parse(String string) {
    for (final a in _arguments) {
      if (a.label.toLowerCase() == string.toLowerCase()) {
        return a;
      }
    }
    throw Exception("Unknown argument: $string");
  }
}
