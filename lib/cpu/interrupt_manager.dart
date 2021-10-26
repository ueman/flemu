import 'package:gb_emulator/address_space.dart';

class InterruptType {
  const InterruptType.vBlank() : handler = 0x0040;
  const InterruptType.lcdc() : handler = 0x0048;
  const InterruptType.timer() : handler = 0x0050;
  const InterruptType.serial() : handler = 0x0058;
  const InterruptType.p10_13() : handler = 0x0060;

  final int handler;
  int get ordinal => handler;

  static const List<InterruptType> values = [
    InterruptType.vBlank(),
    InterruptType.lcdc(),
    InterruptType.timer(),
    InterruptType.serial(),
    InterruptType.p10_13(),
  ];
}

class InterruptManager implements AddressSpace {
  final bool gbc;

  bool ime = false;

  int interruptFlag = 0xe1;

  int interruptEnabled = 0;

  int pendingEnableInterrupts = -1;

  int pendingDisableInterrupts = -1;

  InterruptManager(this.gbc);

  void enableInterrupts(bool withDelay) {
    pendingDisableInterrupts = -1;
    if (withDelay) {
      if (pendingEnableInterrupts == -1) {
        pendingEnableInterrupts = 1;
      }
    } else {
      pendingEnableInterrupts = -1;
      ime = true;
    }
  }

  void disableInterrupts(bool withDelay) {
    pendingEnableInterrupts = -1;
    if (withDelay && gbc) {
      if (pendingDisableInterrupts == -1) {
        pendingDisableInterrupts = 1;
      }
    } else {
      pendingDisableInterrupts = -1;
      ime = false;
    }
  }

  void requestInterrupt(InterruptType type) {
    interruptFlag = interruptFlag | (1 << type.handler);
  }

  void clearInterrupt(InterruptType type) {
    interruptFlag = interruptFlag & ~(1 << type.handler);
  }

  void onInstructionFinished() {
    if (pendingEnableInterrupts != -1) {
      if (pendingEnableInterrupts-- == 0) {
        enableInterrupts(false);
      }
    }
    if (pendingDisableInterrupts != -1) {
      if (pendingDisableInterrupts-- == 0) {
        disableInterrupts(false);
      }
    }
  }

  bool isIme() {
    return ime;
  }

  bool isInterruptRequested() {
    return (interruptFlag & interruptEnabled) != 0;
  }

  bool isHaltBug() {
    return (interruptFlag & interruptEnabled & 0x1f) != 0 && !ime;
  }

  @override
  bool accepts(int address) {
    return address == 0xff0f || address == 0xffff;
  }

  @override
  void setByte(int address, int value) {
    switch (address) {
      case 0xff0f:
        interruptFlag = value | 0xe0;
        break;

      case 0xffff:
        interruptEnabled = value;
        break;
    }
  }

  @override
  int getByte(int address) {
    switch (address) {
      case 0xff0f:
        return interruptFlag;

      case 0xffff:
        return interruptEnabled;

      default:
        return 0xff;
    }
  }
}
