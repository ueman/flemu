import 'package:gb_emulator/address_space.dart';

enum CorruptionType {
  incDec,
  pop1,
  pop2,
  push1,
  push2,
  ldHl,
}

class SpriteBug {
  static void corruptOam(
      AddressSpace addressSpace, CorruptionType type, int ticksInLine) {
    int cpuCycle = (ticksInLine + 1) ~/ 4 + 1;
    switch (type) {
      case CorruptionType.incDec:
        if (cpuCycle >= 2) {
          _copyValues(
              addressSpace, (cpuCycle - 2) * 8 + 2, (cpuCycle - 1) * 8 + 2, 6);
        }
        break;

      case CorruptionType.pop1:
        if (cpuCycle >= 4) {
          _copyValues(
              addressSpace, (cpuCycle - 3) * 8 + 2, (cpuCycle - 4) * 8 + 2, 8);
          _copyValues(
              addressSpace, (cpuCycle - 3) * 8 + 8, (cpuCycle - 4) * 8 + 0, 2);
          _copyValues(
              addressSpace, (cpuCycle - 4) * 8 + 2, (cpuCycle - 2) * 8 + 2, 6);
        }
        break;

      case CorruptionType.pop2:
        if (cpuCycle >= 5) {
          _copyValues(
              addressSpace, (cpuCycle - 5) * 8 + 0, (cpuCycle - 2) * 8 + 0, 8);
        }
        break;

      case CorruptionType.push1:
        if (cpuCycle >= 4) {
          _copyValues(
              addressSpace, (cpuCycle - 4) * 8 + 2, (cpuCycle - 3) * 8 + 2, 8);
          _copyValues(
              addressSpace, (cpuCycle - 3) * 8 + 2, (cpuCycle - 1) * 8 + 2, 6);
        }
        break;

      case CorruptionType.push2:
        if (cpuCycle >= 5) {
          _copyValues(
              addressSpace, (cpuCycle - 4) * 8 + 2, (cpuCycle - 3) * 8 + 2, 8);
        }
        break;

      case CorruptionType.ldHl:
        if (cpuCycle >= 4) {
          _copyValues(
              addressSpace, (cpuCycle - 3) * 8 + 2, (cpuCycle - 4) * 8 + 2, 8);
          _copyValues(
              addressSpace, (cpuCycle - 3) * 8 + 8, (cpuCycle - 4) * 8 + 0, 2);
          _copyValues(
              addressSpace, (cpuCycle - 4) * 8 + 2, (cpuCycle - 2) * 8 + 2, 6);
        }
        break;
    }
  }

  static void _copyValues(
      AddressSpace addressSpace, int from, int to, int length) {
    for (int i = length - 1; i >= 0; i--) {
      int b = addressSpace.getByte(0xfe00 + from + i) % 0xff;
      addressSpace.setByte(0xfe00 + to + i, b);
    }
  }
}
