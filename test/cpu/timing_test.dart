import 'package:flutter_test/flutter_test.dart';
import 'package:gb_emulator/cpu/cpu.dart';
import 'package:gb_emulator/cpu/interrupt_manager.dart';
import 'package:gb_emulator/cpu/op_code/op_code.dart';
import 'package:gb_emulator/cpu/speed_mode.dart';
import 'package:gb_emulator/gpu/display.dart';
import 'package:gb_emulator/int_x.dart';
import 'package:gb_emulator/memory/ram.dart';

void main() {
  const offset = 0x100;

  final memory = Ram(0x00, 0x10000);
  final cpu = Cpu(
    memory,
    InterruptManager(false),
    null,
    NullDisplay(),
    SpeedMode(),
  );

  void assertTiming(int expectedTiming, List<int> opcodes) {
    for (int i = 0; i < opcodes.length; i++) {
      memory.setByte(offset + i, opcodes[i]);
    }
    cpu.clearState();
    cpu.getRegisters().pc = offset;

    int ticks = 0;
    Opcode? opcode;
    do {
      cpu.tick();
      if (opcode == null && cpu.getCurrentOpcode() != null) {
        opcode = cpu.getCurrentOpcode();
      }
      ticks++;
    } while (cpu.getState() != CpuState.opcode || ticks < 4);

    if (opcode == null) {
      expect(
        expectedTiming,
        ticks,
        reason: "Invalid timing value for ${hexArray(opcodes)}",
      );
    } else {
      expect(
        expectedTiming,
        ticks,
        reason: "Invalid timing value for [${opcode.toString()}]",
      );
    }
  }

  test('timing test', () {
    assertTiming(16, [0xc9, 0, 0]); // RET
    assertTiming(16, [0xd9, 0, 0]); // RETI
    cpu.getRegisters().flags.setZ(false);
    assertTiming(20, [0xc0, 0, 0]); // RET NZ
    cpu.getRegisters().flags.setZ(true);
    assertTiming(8, [0xc0, 0, 0]); // RET NZ
    assertTiming(24, [0xcd, 0, 0]); // CALL a16
    assertTiming(16, [0xc5]); // PUSH BC
    assertTiming(12, [0xf1]); // POP AF

    assertTiming(8, [0xd6, 00]); // SUB A,d8

    cpu.getRegisters().flags.setC(true);
    assertTiming(8, [0x30, 00]); // JR nc,r8

    cpu.getRegisters().flags.setC(false);
    assertTiming(12, [0x30, 00]); // JR nc,r8

    cpu.getRegisters().flags.setC(true);
    assertTiming(12, [0xd2, 00]); // JP nc,a16

    cpu.getRegisters().flags.setC(false);
    assertTiming(16, [0xd2, 00]); // JP nc,a16

    assertTiming(16, [0xc3, 00, 00]); // JP a16

    assertTiming(4, [0xaf]); // XOR a
    assertTiming(12, [0xe0, 0x05]); // LD (ff00+05),A
    assertTiming(12, [0xf0, 0x05]); // LD A,(ff00+05)
    assertTiming(4, [0xb7]); // OR

    assertTiming(4, [0x7b]); // LDA A,E
    assertTiming(8, [0xd6, 0x00]); // SUB A,d8
    assertTiming(8, [0xcb, 0x12]); // RL D
    assertTiming(4, [0x87]); // ADD A
    assertTiming(4, [0xf3]); // DI
    assertTiming(8, [0x32]); // LD (HL-),A
    assertTiming(12, [0x36]); // LD (HL),d8
    assertTiming(16, [0xea, 0x00, 0x00]); // LD (a16),A
    assertTiming(8, [0x09]); // ADD HL,BC
    assertTiming(16, [0xc7]); // RST 00H

    assertTiming(8, [0x3e, 0x51]); // LDA A,51
    assertTiming(4, [0x1f]); // RRA
    assertTiming(8, [0xce, 0x01]); // ADC A,01
    assertTiming(4, [0x00]); // NOP
  });
}

String hexArray(List<int> data) {
  return '[${data.map((e) => e.toHex()).join(' ')}]';
}
