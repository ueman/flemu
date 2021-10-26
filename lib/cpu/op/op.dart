import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/cpu/interrupt_manager.dart';
import 'package:gb_emulator/cpu/registers.dart';
import 'package:gb_emulator/gpu/sprite_bug.dart';

typedef Execute = int Function(
  Registers registers,
  AddressSpace addressSpace,
  List<int> args,
  int context,
);

typedef SwitchInterrupts = void Function(InterruptManager interruptManager);

typedef Proceed = bool Function(Registers registers);

typedef CausesOemBug = CorruptionType? Function(
  Registers registers,
  int context,
);

int _defaultExecute(
  Registers registers,
  AddressSpace addressSpace,
  List<int> args,
  int context,
) =>
    context;

void _defaultSwitchInterrupts(InterruptManager interruptManager) {}

bool _defaultProceed(Registers registers) => true;

CorruptionType? _defaultCausesOemBug(Registers registers, int context) {
  return null;
}

class Op {
  Op({
    this.readsMemory = false,
    this.writesMemory = false,
    this.operandLength = 0,
    this.forceFinishCycle = false,
    this.execute = _defaultExecute,
    this.switchInterrupts = _defaultSwitchInterrupts,
    this.proceed = _defaultProceed,
    this.causesOemBug = _defaultCausesOemBug,
    this.description = '',
  });

  final String description;
  final bool readsMemory;
  final bool writesMemory;
  final int operandLength;
  final bool forceFinishCycle;
  final Execute execute;
  final SwitchInterrupts switchInterrupts;
  final Proceed proceed;
  final CausesOemBug causesOemBug;

  @override
  String toString() => description;
}
