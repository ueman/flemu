import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/cpu/interrupt_manager.dart';
import 'package:gb_emulator/cpu/op/op.dart';
import 'package:gb_emulator/cpu/op_code/op_code.dart';
import 'package:gb_emulator/cpu/opcodes.dart' as opcodes;
import 'package:gb_emulator/cpu/registers.dart';
import 'package:gb_emulator/cpu/speed_mode.dart';
import 'package:gb_emulator/gpu/display.dart';
import 'package:gb_emulator/gpu/gpu.dart';
import 'package:gb_emulator/gpu/gpu_register.dart';
import 'package:gb_emulator/gpu/sprite_bug.dart';
import 'package:gb_emulator/int_x.dart';

enum CpuState {
  opcode,
  extOpcode,
  operand,
  running,
  irqReadIf,
  irqReadIe,
  irqPush1,
  irqPush2,
  irqJump,
  stopped,
  halted,
}

class Cpu {
  final Registers _registers = Registers();

  final AddressSpace _addressSpace;

  final InterruptManager _interruptManager;

  final Gpu? _gpu;

  final Display _display;

  final SpeedMode _speedMode;

  int _opcode1 = 0;
  int _opcode2 = 0;

  final List<int> _operand = List.generate(2, (index) => 0);

  Opcode? _currentOpcode;

  List<Op>? ops;

  int _operandIndex = 0;

  int _opIndex = 0;

  CpuState _state = CpuState.opcode;

  int _opContext = 0;

  int _interruptFlag = 0;

  int _interruptEnabled = 0;

  InterruptType? _requestedIrq;

  int _clockCycle = 0;

  bool _haltBugMode = false;

  Cpu(
    this._addressSpace,
    this._interruptManager,
    this._gpu,
    this._display,
    this._speedMode,
  );

  void tick() {
    if (++_clockCycle >= (4 / _speedMode.getSpeedMode())) {
      _clockCycle = 0;
    } else {
      return;
    }

    if (_state == CpuState.opcode ||
        _state == CpuState.halted ||
        _state == CpuState.stopped) {
      if (_interruptManager.isIme() &&
          _interruptManager.isInterruptRequested()) {
        if (_state == CpuState.stopped) {
          _display.enableLcd();
        }
        _state = CpuState.irqReadIf;
      }
    }

    if (_state == CpuState.irqReadIf ||
        _state == CpuState.irqReadIe ||
        _state == CpuState.irqPush1 ||
        _state == CpuState.irqPush2 ||
        _state == CpuState.irqJump) {
      _handleInterrupt();
      return;
    }

    if (_state == CpuState.halted && _interruptManager.isInterruptRequested()) {
      _state = CpuState.opcode;
    }

    if (_state == CpuState.halted || _state == CpuState.stopped) {
      return;
    }

    bool accessedMemory = false;
    while (true) {
      int pc = _registers.pc;
      switch (_state) {
        case CpuState.opcode:
          clearState();
          _opcode1 = _addressSpace.getByte(pc);
          accessedMemory = true;
          if (_opcode1 == 0xcb) {
            _state = CpuState.extOpcode;
          } else if (_opcode1 == 0x10) {
            _currentOpcode = opcodes.commands[_opcode1];
            _state = CpuState.extOpcode;
          } else {
            _state = CpuState.operand;
            _currentOpcode = opcodes.commands[_opcode1];
            if (_currentOpcode == null) {
              throw Exception("No command for 0x${_opcode1.toHex()}");
            }
          }
          if (!_haltBugMode) {
            _registers.incrementPC();
          } else {
            _haltBugMode = false;
          }
          break;

        case CpuState.extOpcode:
          if (accessedMemory) {
            return;
          }
          accessedMemory = true;
          _opcode2 = _addressSpace.getByte(pc);
          _currentOpcode ??= opcodes.extCommands[_opcode2];
          if (_currentOpcode == null) {
            throw Exception("No command for %0xcb 0x${_opcode2.toHex()}");
          }
          _state = CpuState.operand;
          _registers.incrementPC();
          break;

        case CpuState.operand:
          while (_operandIndex < _currentOpcode!.operandLength) {
            if (accessedMemory) {
              return;
            }
            accessedMemory = true;
            _operand[_operandIndex++] = _addressSpace.getByte(pc);
            _registers.incrementPC();
          }
          ops = _currentOpcode!.ops;
          _state = CpuState.running;
          break;

        case CpuState.running:
          if (_opcode1 == 0x10) {
            if (_speedMode.onStop()) {
              _state = CpuState.opcode;
            } else {
              _state = CpuState.stopped;
              _display.disableLcd();
            }
            return;
          } else if (_opcode1 == 0x76) {
            if (_interruptManager.isHaltBug()) {
              _state = CpuState.opcode;
              _haltBugMode = true;
              return;
            } else {
              _state = CpuState.halted;
              return;
            }
          }

          if (_opIndex < ops!.length) {
            Op op = ops![_opIndex];
            bool opAccessesMemory = op.readsMemory || op.writesMemory;
            if (accessedMemory && opAccessesMemory) {
              return;
            }
            _opIndex++;

            final corruptionType = op.causesOemBug(_registers, _opContext);
            if (corruptionType != null) {
              _handleSpriteBug(corruptionType);
            }
            _opContext =
                op.execute(_registers, _addressSpace, _operand, _opContext);
            op.switchInterrupts(_interruptManager);

            if (!op.proceed(_registers)) {
              _opIndex = ops!.length;
              break;
            }

            if (op.forceFinishCycle) {
              return;
            }

            if (opAccessesMemory) {
              accessedMemory = true;
            }
          }

          if (_opIndex >= ops!.length) {
            _state = CpuState.opcode;
            _operandIndex = 0;
            _interruptManager.onInstructionFinished();
            return;
          }
          break;

        case CpuState.halted:
        case CpuState.stopped:
          return;
      }
    }
  }

  void _handleInterrupt() {
    switch (_state) {
      case CpuState.irqReadIf:
        _interruptFlag = _addressSpace.getByte(0xff0f);
        _state = CpuState.irqReadIe;
        break;

      case CpuState.irqReadIe:
        _interruptEnabled = _addressSpace.getByte(0xffff);
        _requestedIrq = null;
        for (final irq in InterruptType.values) {
          if ((_interruptFlag & _interruptEnabled & (1 << irq.ordinal)) != 0) {
            _requestedIrq = irq;
            break;
          }
        }
        if (_requestedIrq == null) {
          _state = CpuState.opcode;
        } else {
          _state = CpuState.irqPush1;
          _interruptManager.clearInterrupt(_requestedIrq!);
          _interruptManager.disableInterrupts(false);
        }
        break;

      case CpuState.irqPush1:
        _registers.decrementSP();
        _addressSpace.setByte(_registers.sp, (_registers.pc & 0xff00) >> 8);
        _state = CpuState.irqPush2;
        break;

      case CpuState.irqPush2:
        _registers.decrementSP();
        _addressSpace.setByte(_registers.sp, _registers.pc & 0x00ff);
        _state = CpuState.irqJump;
        break;

      case CpuState.irqJump:
        _registers.pc = _requestedIrq!.handler;
        _requestedIrq = null;
        _state = CpuState.opcode;
        break;
    }
  }

  void _handleSpriteBug(CorruptionType type) {
    if (!(_gpu?.lcdc.isLcdEnabled() ?? false)) {
      return;
    }
    int stat = _addressSpace.getByte(const GpuRegister.STAT().getAddress());
    if ((stat & 3 /* 0b11 */) == GpuMode.OamSearch.index &&
        (_gpu?.getTicksInLine() ?? 0) < 79) {
      SpriteBug.corruptOam(_addressSpace, type, _gpu?.getTicksInLine() ?? 0);
    }
  }

  Registers getRegisters() => _registers;

  void clearState() {
    _opcode1 = 0;
    _opcode2 = 0;
    _currentOpcode = null;
    ops = null;

    _operand[0] = 0x00;
    _operand[1] = 0x00;
    _operandIndex = 0;

    _opIndex = 0;
    _opContext = 0;

    _interruptFlag = 0;
    _interruptEnabled = 0;
    _requestedIrq = null;
  }

  CpuState getState() => _state;

  Opcode? getCurrentOpcode() => _currentOpcode;
}
