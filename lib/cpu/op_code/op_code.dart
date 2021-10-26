import 'package:gb_emulator/cpu/op/op.dart';
import 'package:gb_emulator/cpu/op_code/op_code_builder.dart';
import 'dart:math' as math;

import 'package:gb_emulator/int_x.dart';

class Opcode {
  final int opcode;
  final String label;
  final List<Op> ops;
  final int operandLength;

  Opcode(OpcodeBuilder builder)
      : opcode = builder.opcode,
        label = builder.label,
        ops = List.unmodifiable(builder.ops),
        operandLength = builder.ops.isEmpty
            ? 0
            : builder.ops.map((e) => e.operandLength).reduce(math.max);

  @override
  String toString() {
    return "${opcode.toHex()} $label";
  }
}
