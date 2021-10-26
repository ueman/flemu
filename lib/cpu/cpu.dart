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
  OPCODE,
  EXT_OPCODE,
  OPERAND,
  RUNNING,
  IRQ_READ_IF,
  IRQ_READ_IE,
  IRQ_PUSH_1,
  IRQ_PUSH_2,
  IRQ_JUMP,
  STOPPED,
  HALTED,
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

  CpuState _state = CpuState.OPCODE;

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

    if (_state == CpuState.OPCODE ||
        _state == CpuState.HALTED ||
        _state == CpuState.STOPPED) {
      if (_interruptManager.isIme() &&
          _interruptManager.isInterruptRequested()) {
        if (_state == CpuState.STOPPED) {
          _display.enableLcd();
        }
        _state = CpuState.IRQ_READ_IF;
      }
    }

    if (_state == CpuState.IRQ_READ_IF ||
        _state == CpuState.IRQ_READ_IE ||
        _state == CpuState.IRQ_PUSH_1 ||
        _state == CpuState.IRQ_PUSH_2 ||
        _state == CpuState.IRQ_JUMP) {
      _handleInterrupt();
      return;
    }

    if (_state == CpuState.HALTED && _interruptManager.isInterruptRequested()) {
      _state = CpuState.OPCODE;
    }

    if (_state == CpuState.HALTED || _state == CpuState.STOPPED) {
      return;
    }

    bool accessedMemory = false;
    while (true) {
      int pc = _registers.pc;
      switch (_state) {
        case CpuState.OPCODE:
          clearState();
          _opcode1 = _addressSpace.getByte(pc);
          accessedMemory = true;
          if (_opcode1 == 0xcb) {
            _state = CpuState.EXT_OPCODE;
          } else if (_opcode1 == 0x10) {
            _currentOpcode = opcodes.COMMANDS[_opcode1];
            _state = CpuState.EXT_OPCODE;
          } else {
            _state = CpuState.OPERAND;
            _currentOpcode = opcodes.COMMANDS[_opcode1];
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

        case CpuState.EXT_OPCODE:
          if (accessedMemory) {
            return;
          }
          accessedMemory = true;
          _opcode2 = _addressSpace.getByte(pc);
          if (_currentOpcode == null) {
            _currentOpcode = opcodes.EXT_COMMANDS[_opcode2];
          }
          if (_currentOpcode == null) {
            throw Exception("No command for %0xcb 0x${_opcode2.toHex()}");
          }
          _state = CpuState.OPERAND;
          _registers.incrementPC();
          break;

        case CpuState.OPERAND:
          while (_operandIndex < _currentOpcode!.operandLength) {
            if (accessedMemory) {
              return;
            }
            accessedMemory = true;
            _operand[_operandIndex++] = _addressSpace.getByte(pc);
            _registers.incrementPC();
          }
          ops = _currentOpcode!.ops;
          _state = CpuState.RUNNING;
          break;

        case CpuState.RUNNING:
          if (_opcode1 == 0x10) {
            if (_speedMode.onStop()) {
              _state = CpuState.OPCODE;
            } else {
              _state = CpuState.STOPPED;
              _display.disableLcd();
            }
            return;
          } else if (_opcode1 == 0x76) {
            if (_interruptManager.isHaltBug()) {
              _state = CpuState.OPCODE;
              _haltBugMode = true;
              return;
            } else {
              _state = CpuState.HALTED;
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
            _state = CpuState.OPCODE;
            _operandIndex = 0;
            _interruptManager.onInstructionFinished();
            return;
          }
          break;

        case CpuState.HALTED:
        case CpuState.STOPPED:
          return;
      }
    }
  }

  void _handleInterrupt() {
    switch (_state) {
      case CpuState.IRQ_READ_IF:
        _interruptFlag = _addressSpace.getByte(0xff0f);
        _state = CpuState.IRQ_READ_IE;
        break;

      case CpuState.IRQ_READ_IE:
        _interruptEnabled = _addressSpace.getByte(0xffff);
        _requestedIrq = null;
        for (final irq in InterruptType.values) {
          if ((_interruptFlag & _interruptEnabled & (1 << irq.ordinal)) != 0) {
            _requestedIrq = irq;
            break;
          }
        }
        if (_requestedIrq == null) {
          _state = CpuState.OPCODE;
        } else {
          _state = CpuState.IRQ_PUSH_1;
          _interruptManager.clearInterrupt(_requestedIrq!);
          _interruptManager.disableInterrupts(false);
        }
        break;

      case CpuState.IRQ_PUSH_1:
        _registers.decrementSP();
        _addressSpace.setByte(_registers.sp, (_registers.pc & 0xff00) >> 8);
        _state = CpuState.IRQ_PUSH_2;
        break;

      case CpuState.IRQ_PUSH_2:
        _registers.decrementSP();
        _addressSpace.setByte(_registers.sp, _registers.pc & 0x00ff);
        _state = CpuState.IRQ_JUMP;
        break;

      case CpuState.IRQ_JUMP:
        _registers.pc = _requestedIrq!.handler;
        _requestedIrq = null;
        _state = CpuState.OPCODE;
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
