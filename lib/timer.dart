import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/cpu/interrupt_manager.dart';
import 'package:gb_emulator/cpu/speed_mode.dart';

class Timer implements AddressSpace {
  final SpeedMode speedMode;

  final InterruptManager interruptManager;

  static final List<int> freqToBit = [9, 3, 5, 7];

  int div = 0;
  int tac = 0;
  int tma = 0;
  int tima = 0;

  bool previousBit = false;

  bool overflow = false;

  int ticksSinceOverflow = 0;

  Timer(this.interruptManager, this.speedMode);

  void tick() {
    updateDiv((div + 1) & 0xffff);
    if (overflow) {
      ticksSinceOverflow++;
      if (ticksSinceOverflow == 4) {
        interruptManager.requestInterrupt(const InterruptType.timer());
      }
      if (ticksSinceOverflow == 5) {
        tima = tma;
      }
      if (ticksSinceOverflow == 6) {
        tima = tma;
        overflow = false;
        ticksSinceOverflow = 0;
      }
    }
  }

  void incTima() {
    tima++;
    tima %= 0x100;
    if (tima == 0) {
      overflow = true;
      ticksSinceOverflow = 0;
    }
  }

  void updateDiv(int newDiv) {
    div = newDiv;
    int bitPos = freqToBit[tac & 3]; // 3 == 0b11
    bitPos <<= speedMode.getSpeedMode() - 1;
    var bit = (div & (1 << bitPos)) != 0;
    bit &= (tac & (1 << 2)) != 0;
    if (!bit && previousBit) {
      incTima();
    }
    previousBit = bit;
  }

  @override
  bool accepts(int address) {
    return address >= 0xff04 && address <= 0xff07;
  }

  @override
  void setByte(int address, int value) {
    switch (address) {
      case 0xff04:
        updateDiv(0);
        break;

      case 0xff05:
        if (ticksSinceOverflow < 5) {
          tima = value;
          overflow = false;
          ticksSinceOverflow = 0;
        }
        break;

      case 0xff06:
        tma = value;
        break;

      case 0xff07:
        tac = value;
        break;
    }
  }

  @override
  int getByte(int address) {
    switch (address) {
      case 0xff04:
        return div >> 8;

      case 0xff05:
        return tima;

      case 0xff06:
        return tma;

      case 0xff07:
        return tac | 248; // 248 == 0b11111000;
    }
    throw Exception('Invalid argument: $address');
  }
}
