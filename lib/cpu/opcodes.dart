import 'package:gb_emulator/cpu/op_code/op_code.dart';
import 'package:gb_emulator/cpu/op_code/op_code_builder.dart';
import 'package:gb_emulator/int_x.dart';

final List<Opcode> commands = () {
  List<OpcodeBuilder?> opcodes = List.generate(
      256, (index) => null); // should not have more than 256 elements

  _regCmd(opcodes, 0x00, "NOP");

  for (final t in indexedList(0x01, 0x10, ["BC", "DE", "HL", "SP"])) {
    _regLoad(opcodes, t.key, t.value, "d16");
  }

  for (final t in indexedList(0x02, 0x10, ["(BC)", "(DE)"])) {
    _regLoad(opcodes, t.key, t.value, "A");
  }

  for (final t in indexedList(0x03, 0x10, ["BC", "DE", "HL", "SP"])) {
    _regCmd(opcodes, t, "INC {}")
      ..load(t.value)
      ..alu("INC")
      ..store(t.value);
  }

  for (final t
      in indexedList(0x04, 0x08, ["B", "C", "D", "E", "H", "L", "(HL)", "A"])) {
    _regCmd(opcodes, t, "INC {}")
      ..load(t.value)
      ..alu("INC")
      ..store(t.value);
  }

  for (final t
      in indexedList(0x05, 0x08, ["B", "C", "D", "E", "H", "L", "(HL)", "A"])) {
    _regCmd(opcodes, t, "DEC {}")
      ..load(t.value)
      ..alu("DEC")
      ..store(t.value);
  }

  for (final t
      in indexedList(0x06, 0x08, ["B", "C", "D", "E", "H", "L", "(HL)", "A"])) {
    _regLoad(opcodes, t.key, t.value, "d8");
  }

  for (final o in indexedList(0x07, 0x08, ["RLC", "RRC", "RL", "RR"])) {
    _regCmd(opcodes, o, o.value + "A")
      ..load("A")
      ..alu(o.value)
      ..clearZ()
      ..store("A");
  }

  _regLoad(opcodes, 0x08, "(a16)", "SP");

  for (final t in indexedList(0x09, 0x10, ["BC", "DE", "HL", "SP"])) {
    _regCmd(opcodes, t, "ADD HL,{}")
      ..load("HL")
      ..aluFromString("ADD", t.value)
      ..store("HL");
  }

  for (final t in indexedList(0x0a, 0x10, ["(BC)", "(DE)"])) {
    _regLoad(opcodes, t.key, "A", t.value);
  }

  for (final t in indexedList(0x0b, 0x10, ["BC", "DE", "HL", "SP"])) {
    _regCmd(opcodes, t, "DEC {}")
      ..load(t.value)
      ..alu("DEC")
      ..store(t.value);
  }

  _regCmd(opcodes, 0x10, "STOP");

  _regCmd(opcodes, 0x18, "JR r8")
    ..load("PC")
    ..aluFromString("ADD", "r8")
    ..store("PC");

  for (final c in indexedList(0x20, 0x08, ["NZ", "Z", "NC", "C"])) {
    _regCmd(opcodes, c, "JR {},r8")
      ..load("PC")
      ..proceedIf(c.value)
      ..aluFromString("ADD", "r8")
      ..store("PC");
  }

  _regCmd(opcodes, 0x22, "LD (HL+),A")
    ..copyByte("(HL)", "A")
    ..aluHL("INC");
  _regCmd(opcodes, 0x2a, "LD A,(HL+)")
    ..copyByte("A", "(HL)")
    ..aluHL("INC");

  _regCmd(opcodes, 0x27, "DAA")
    ..load("A")
    ..alu("DAA")
    ..store("A");
  _regCmd(opcodes, 0x2f, "CPL")
    ..load("A")
    ..alu("CPL")
    ..store("A");

  _regCmd(opcodes, 0x32, "LD (HL-),A")
    ..copyByte("(HL)", "A")
    ..aluHL("DEC");
  _regCmd(opcodes, 0x3a, "LD A,(HL-)")
    ..copyByte("A", "(HL)")
    ..aluHL("DEC");

  _regCmd(opcodes, 0x37, "SCF")
    ..load("A")
    ..alu("SCF")
    ..store("A");
  _regCmd(opcodes, 0x3f, "CCF")
    ..load("A")
    ..alu("CCF")
    ..store("A");

  for (final t
      in indexedList(0x40, 0x08, ["B", "C", "D", "E", "H", "L", "(HL)", "A"])) {
    for (final s in indexedList(
        t.key, 0x01, ["B", "C", "D", "E", "H", "L", "(HL)", "A"])) {
      if (s.key == 0x76) {
        continue;
      }
      _regLoad(opcodes, s.key, t.value, s.value);
    }
  }

  _regCmd(opcodes, 0x76, "HALT");

  for (final o in indexedList(
      0x80, 0x08, ["ADD", "ADC", "SUB", "SBC", "AND", "XOR", "OR", "CP"])) {
    for (final t in indexedList(
        o.key, 0x01, ["B", "C", "D", "E", "H", "L", "(HL)", "A"])) {
      _regCmd(opcodes, t, o.value + " {}")
        ..load("A")
        ..aluFromString(o.value, t.value)
        ..store("A");
    }
  }

  for (final c in indexedList(0xc0, 0x08, ["NZ", "Z", "NC", "C"])) {
    _regCmd(opcodes, c, "RET {}")
      ..extraCycle()
      ..proceedIf(c.value)
      ..pop()
      ..forceFinish()
      ..store("PC");
  }

  for (final t in indexedList(0xc1, 0x10, ["BC", "DE", "HL", "AF"])) {
    _regCmd(opcodes, t, "POP {}")
      ..pop()
      ..store(t.value);
  }

  for (final c in indexedList(0xc2, 0x08, ["NZ", "Z", "NC", "C"])) {
    _regCmd(opcodes, c, "JP {},a16")
      ..load("a16")
      ..proceedIf(c.value)
      ..store("PC")
      ..extraCycle();
  }

  _regCmd(opcodes, 0xc3, "JP a16")
    ..load("a16")
    ..store("PC")
    ..extraCycle();

  for (final c in indexedList(0xc4, 0x08, ["NZ", "Z", "NC", "C"])) {
    _regCmd(opcodes, c, "CALL {},a16")
      ..proceedIf(c.value)
      ..extraCycle()
      ..load("PC")
      ..push()
      ..load("a16")
      ..store("PC");
  }

  for (final t in indexedList(0xc5, 0x10, ["BC", "DE", "HL", "AF"])) {
    _regCmd(opcodes, t, "PUSH {}")
      ..extraCycle()
      ..load(t.value)
      ..push();
  }

  for (final o in indexedList(
      0xc6, 0x08, ["ADD", "ADC", "SUB", "SBC", "AND", "XOR", "OR", "CP"])) {
    _regCmd(opcodes, o, o.value + " d8")
      ..load("A")
      ..aluFromString(o.value, "d8")
      ..store("A");
  }

  for (int i = 0xc7, j = 0x00; i <= 0xf7; i += 0x10, j += 0x10) {
    _regCmd(opcodes, i, "RST ${j.toHex()}H")
      ..load("PC")
      ..push()
      ..forceFinish()
      ..loadWord(j)
      ..store("PC");
  }

  _regCmd(opcodes, 0xc9, "RET")
    ..pop()
    ..forceFinish()
    ..store("PC");

  _regCmd(opcodes, 0xcd, "CALL a16")
    ..load("PC")
    ..extraCycle()
    ..push()
    ..load("a16")
    ..store("PC");

  for (int i = 0xcf, j = 0x08; i <= 0xff; i += 0x10, j += 0x10) {
    _regCmd(opcodes, i, "RST ${j.toHex()}H")
      ..load("PC")
      ..push()
      ..forceFinish()
      ..loadWord(j)
      ..store("PC");
  }

  _regCmd(opcodes, 0xd9, "RETI")
    ..pop()
    ..forceFinish()
    ..store("PC")
    ..switchInterrupts(true, false);

  _regLoad(opcodes, 0xe2, "(C)", "A");
  _regLoad(opcodes, 0xf2, "A", "(C)");

  _regCmd(opcodes, 0xe9, "JP (HL)")
    ..load("HL")
    ..store("PC");

  _regCmd(opcodes, 0xe0, "LDH (a8),A").copyByte("(a8)", "A");
  _regCmd(opcodes, 0xf0, "LDH A,(a8)").copyByte("A", "(a8)");

  _regCmd(opcodes, 0xe8, "ADD SP,r8")
    ..load("SP")
    ..aluFromString("ADD_SP", "r8")
    ..extraCycle()
    ..store("SP");
  _regCmd(opcodes, 0xf8, "LD HL,SP+r8")
    ..load("SP")
    ..aluFromString("ADD_SP", "r8")
    ..store("HL");

  _regLoad(opcodes, 0xea, "(a16)", "A");
  _regLoad(opcodes, 0xfa, "A", "(a16)");

  _regCmd(opcodes, 0xf3, "DI").switchInterrupts(false, true);
  _regCmd(opcodes, 0xfb, "EI").switchInterrupts(true, true);

  _regLoad(opcodes, 0xf9, "SP", "HL").extraCycle();

  List<Opcode> commands = []; // new ArrayList<>(0x100);

  for (final b in opcodes) {
    if (b != null) {
      commands.add(b.build());
    }
  }

  return List<Opcode>.unmodifiable(commands);
}();

final List<Opcode> extCommands = () {
  List<OpcodeBuilder?> extOpcodes = List.generate(0x100, (index) => null);

  for (final o in indexedList(
      0x00, 0x08, ["RLC", "RRC", "RL", "RR", "SLA", "SRA", "SWAP", "SRL"])) {
    for (final t in indexedList(
        o.key, 0x01, ["B", "C", "D", "E", "H", "L", "(HL)", "A"])) {
      _regCmd(extOpcodes, t, o.value + " {}")
        ..load(t.value)
        ..alu(o.value)
        ..store(t.value);
    }
  }

  for (final o in indexedList(0x40, 0x40, ["BIT", "RES", "SET"])) {
    for (int b = 0; b < 0x08; b++) {
      for (final t in indexedList(o.key + b * 0x08, 0x01,
          ["B", "C", "D", "E", "H", "L", "(HL)", "A"])) {
        if ("BIT" == o.value && "(HL)" == t.value) {
          _regCmd(extOpcodes, t, "BIT $b,(HL)").bitHL(b);
        } else {
          _regCmd(extOpcodes, t, "${o.value} $b,${t.value}")
            ..load(t.value)
            ..alu(o.value, b)
            ..store(t.value);
        }
      }
    }
  }

  List<Opcode> extCommands = []; // new ArrayList<>(0x100);

  for (final b in extOpcodes) {
    extCommands.add(b!.build());
  }

  return List<Opcode>.unmodifiable(extCommands);
}();

OpcodeBuilder _regLoad(
  List<OpcodeBuilder?> commands,
  int opcode,
  String target,
  String source,
) {
  return _regCmd(commands, opcode, "LD $target,$source")
    ..copyByte(target, source);
}

OpcodeBuilder _regCmd(
  List<OpcodeBuilder?> commands,
  dynamic opcode,
  String label,
) {
  if (opcode is int) {
    return _regCmdInt(commands, opcode, label);
  }
  if (opcode is MapEntry<int, String>) {
    return _regCmdMap(commands, opcode, label);
  }
  throw Exception('Invalid opcode type ${opcode.runtimeType}');
}

OpcodeBuilder _regCmdInt(
  List<OpcodeBuilder?> commands,
  int opcode,
  String label,
) {
  if (commands[opcode] != null) {
    throw Exception(
      "Opcode ${opcode.toHex()} already exists: ${commands[opcode]}",
    );
  }
  OpcodeBuilder builder = OpcodeBuilder(opcode, label);
  commands[opcode] = builder;
  return builder;
}

OpcodeBuilder _regCmdMap(
  List<OpcodeBuilder?> commands,
  MapEntry<int, String> opcode,
  String label,
) {
  return _regCmd(commands, opcode.key, label.replaceAll("{}", opcode.value));
}

Iterable<MapEntry<int, T>> indexedList<T>(
  int start,
  int step,
  List<T> values,
) {
  Map<int, T> map = {};
  int i = start;
  for (final e in values) {
    map[i] = e;
    i += step;
  }
  return map.entries;
}
