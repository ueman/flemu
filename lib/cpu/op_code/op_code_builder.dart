import 'package:gb_emulator/cpu/alu_function.dart';
import 'package:gb_emulator/cpu/bit_utils.dart';
import 'package:gb_emulator/cpu/op/argument.dart';
import 'package:gb_emulator/cpu/op/data_type.dart';
import 'package:gb_emulator/cpu/op/op.dart';
import 'package:gb_emulator/cpu/op_code/op_code.dart';
import 'package:gb_emulator/gpu/sprite_bug.dart';
import 'package:gb_emulator/int_x.dart';

class OpcodeBuilder {
  static final AluFunctions ALU = AluFunctions();

  static final Set<IntRegistryFunction> OEM_BUG = {
    ALU.findIntAluFunction("INC", DataType.D16)!,
    ALU.findIntAluFunction("DEC", DataType.D16)!,
  };

  final int opcode;

  final String label;

  final List<Op> ops = [];

  DataType? lastDataType;

  OpcodeBuilder(this.opcode, this.label);

  void copyByte(String target, String source) {
    load(source);
    store(target);
  }

  void load(String source) {
    Argument arg = Argument.parse(source);
    lastDataType = arg.dataType;
    ops.add(
      Op(
          readsMemory: arg.memory,
          operandLength: arg.operandLength,
          execute: (registers, addressSpace, args, int context) {
            return arg.read(registers, addressSpace, args);
          },
          description: () {
            if (arg.dataType == DataType.D16) {
              return "${arg.label} → [__]";
            } else {
              return "${arg.label} → [_]";
            }
          }()),
    );
  }

  void loadWord(int value) {
    lastDataType = DataType.D16;
    ops.add(
      Op(
        execute: (registers, addressSpace, args, int context) {
          return value;
        },
        description: "0x${value.toHex()} → [__]",
      ),
    );
  }

  void store(String target) {
    Argument arg = Argument.parse(target);
    if (lastDataType == DataType.D16 && arg == Argument.parse('(a16)')) {
      ops.add(Op(
        writesMemory: arg.memory,
        operandLength: arg.operandLength,
        execute: (registers, addressSpace, args, int context) {
          addressSpace.setByte(toWordFromList(args), context & 0x00ff);
          return context;
        },
        description: "[ _] → ${arg.label}",
      ));
      ops.add(Op(
        writesMemory: arg.memory,
        operandLength: arg.operandLength,
        execute: (registers, addressSpace, args, int context) {
          addressSpace.setByte(
              (toWordFromList(args) + 1) & 0xffff, (context & 0xff00) >> 8);
          return context;
        },
        description: "[_ ] → ${arg.label}",
      ));
    } else if (lastDataType == arg.dataType) {
      ops.add(Op(
        writesMemory: arg.memory,
        operandLength: arg.operandLength,
        execute: (registers, addressSpace, args, int context) {
          arg.write(registers, addressSpace, args, context);
          return context;
        },
        description: () {
          if (arg.dataType == DataType.D16) {
            return "[__] → ${arg.label}";
          } else {
            return "[_] → ${arg.label}";
          }
        }(),
      ));
    } else {
      throw UnimplementedError("Can't write $lastDataType to $target");
    }
  }

  void proceedIf(String condition) {
    ops.add(Op(
      proceed: (registers) {
        switch (condition) {
          case "NZ":
            return !registers.flags.isZ();

          case "Z":
            return registers.flags.isZ();

          case "NC":
            return !registers.flags.isC();

          case "C":
            return registers.flags.isC();
        }
        return false;
      },
      description: "? $condition:",
    ));
  }

  void push() {
    final dec = ALU.findIntAluFunction("DEC", DataType.D16)!;
    ops.add(Op(
      writesMemory: true,
      execute: (registers, addressSpace, args, int context) {
        registers.sp = dec(registers.flags, registers.sp);
        addressSpace.setByte(registers.sp, (context & 0xff00) >> 8);
        return context;
      },
      causesOemBug: (registers, int context) {
        return inOamArea(registers.sp) ? CorruptionType.PUSH_1 : null;
      },
      description: "[_ ] → (SP--)",
    ));
    ops.add(Op(
      writesMemory: true,
      execute: (registers, addressSpace, args, int context) {
        registers.sp = dec(registers.flags, registers.sp);
        addressSpace.setByte(registers.sp, context & 0x00ff);
        return context;
      },
      causesOemBug: (registers, int context) {
        return inOamArea(registers.sp) ? CorruptionType.PUSH_2 : null;
      },
      description: "[ _] → (SP--)",
    ));
  }

  void pop() {
    final inc = ALU.findIntAluFunction("INC", DataType.D16)!;

    lastDataType = DataType.D16;
    ops.add(Op(
      readsMemory: true,
      execute: (registers, addressSpace, args, int context) {
        int lsb = addressSpace.getByte(registers.sp);
        registers.sp = inc(registers.flags, registers.sp);
        return lsb;
      },
      causesOemBug: (registers, int context) {
        return inOamArea(registers.sp) ? CorruptionType.POP_1 : null;
      },
      description: "(SP++) → [ _]",
    ));
    ops.add(Op(
      readsMemory: true,
      execute: (registers, addressSpace, args, int context) {
        int msb = addressSpace.getByte(registers.sp);
        registers.sp = inc(registers.flags, registers.sp);
        return context | (msb << 8);
      },
      causesOemBug: (registers, int context) {
        return inOamArea(registers.sp) ? CorruptionType.POP_2 : null;
      },
      description: "(SP++) → [_ ]",
    ));
  }

  void aluFromString(String operation, String argument2) {
    Argument arg2 = Argument.parse(argument2);
    final func = ALU.findBiAluFunction(operation, lastDataType!, arg2.dataType);
    ops.add(Op(
      readsMemory: arg2.memory,
      operandLength: arg2.operandLength,
      execute: (registers, addressSpace, args, int v1) {
        int v2 = arg2.read(registers, addressSpace, args);
        return func!(registers.flags, v1, v2);
      },
      description: () {
        if (lastDataType == DataType.D16) {
          return "$operation([__],$arg2) → [__]";
        } else {
          return "$operation([_],$arg2) → [_]";
        }
      }(),
    ));
    if (lastDataType == DataType.D16) {
      extraCycle();
    }
  }

  void alu(String operation, [int? d8Value]) {
    if (d8Value != null) {
      return aluDouble(operation, d8Value);
    }
    return aluSingle(operation);
  }

  void aluDouble(String operation, int d8Value) {
    final func = ALU.findBiAluFunction(operation, lastDataType!, DataType.D8);
    ops.add(Op(
      execute: (registers, addressSpace, args, int v1) {
        return func!(registers.flags, v1, d8Value);
      },
      description: "$operation($d8Value,[_]) → [_]",
    ));
    if (lastDataType == DataType.D16) {
      extraCycle();
    }
  }

  void aluSingle(String operation) {
    final func = ALU.findIntAluFunction(operation, lastDataType!)!;
    ops.add(Op(
      execute: (registers, addressSpace, args, int value) {
        return func(registers.flags, value);
      },
      causesOemBug: (registers, int context) {
        return OpcodeBuilder.causesOemBug(func, context)
            ? CorruptionType.INC_DEC
            : null;
      },
      description: () {
        if (lastDataType == DataType.D16) {
          return "$operation([__]) → [__]";
        } else {
          return "$operation([_]) → [_]";
        }
      }(),
    ));
    if (lastDataType == DataType.D16) {
      extraCycle();
    }
  }

  void aluHL(String operation) {
    load("HL");
    final func = ALU.findIntAluFunction(operation, DataType.D16)!;
    ops.add(Op(
      execute: (registers, addressSpace, args, int value) {
        return func(registers.flags, value);
      },
      causesOemBug: (registers, int context) {
        return OpcodeBuilder.causesOemBug(func, context)
            ? CorruptionType.LD_HL
            : null;
      },
      description: "%s(HL) → [__]",
    ));
    store("HL");
  }

  void bitHL(int bit) {
    ops.add(Op(
      readsMemory: true,
      execute: (registers, addressSpace, args, int context) {
        int value = addressSpace.getByte(registers.hl);
        final flags = registers.flags;
        flags.setN(false);
        flags.setH(true);
        if (bit < 8) {
          flags.setZ(!getBit(value, bit));
        }
        return context;
      },
      description: "BIT($bit,HL)",
    ));
  }

  void clearZ() {
    ops.add(Op(
      execute: (registers, addressSpace, args, int context) {
        registers.flags.setZ(false);
        return context;
      },
      description: "0 → Z",
    ));
  }

  void switchInterrupts(bool enable, bool withDelay) {
    ops.add(Op(
      switchInterrupts: (interruptManager) {
        if (enable) {
          interruptManager.enableInterrupts(withDelay);
        } else {
          interruptManager.disableInterrupts(withDelay);
        }
      },
      description: (enable ? "enable" : "disable") + " interrupts",
    ));
  }

  void op(Op op) {
    ops.add(op);
  }

  void extraCycle() {
    ops.add(Op(
      readsMemory: true,
      description: "wait cycle",
    ));
  }

  void forceFinish() {
    ops.add(Op(
      forceFinishCycle: true,
      description: "finish cycle",
    ));
  }

  Opcode build() => Opcode(this);

  @override
  String toString() => label;

  static bool causesOemBug(IntRegistryFunction function, int context) {
    return OEM_BUG.contains(function) && inOamArea(context);
  }

  static bool inOamArea(int address) {
    return address >= 0xfe00 && address <= 0xfeff;
  }
}
