import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/controller/controller.dart';
import 'package:gb_emulator/controller/joypad.dart';
import 'package:gb_emulator/cpu/cpu.dart';
import 'package:gb_emulator/cpu/interrupt_manager.dart';
import 'package:gb_emulator/cpu/registers.dart';
import 'package:gb_emulator/cpu/speed_mode.dart';
import 'package:gb_emulator/gameboy_options.dart';
import 'package:gb_emulator/gpu/display.dart';
import 'package:gb_emulator/gpu/gpu.dart';
import 'package:gb_emulator/memory/cart/cartridge.dart';
import 'package:gb_emulator/memory/dma.dart';
import 'package:gb_emulator/memory/gbc_ram.dart';
import 'package:gb_emulator/memory/hdma.dart';
import 'package:gb_emulator/memory/mmu.dart';
import 'package:gb_emulator/memory/ram.dart';
import 'package:gb_emulator/memory/shadow_address_space.dart';
import 'package:gb_emulator/memory/undocumented_gbc_registers.dart';
import 'package:gb_emulator/serial/serial_endpoint.dart';
import 'package:gb_emulator/serial/serial_port.dart';
import 'package:gb_emulator/sound/sound.dart';
import 'package:gb_emulator/sound/sound_output.dart';
import 'package:gb_emulator/timer.dart';

const int ticksPerSecond = 4194304;

class Gameboy {
  late final InterruptManager _interruptManager = InterruptManager(_gbc);

  late final Gpu _gpu;

  final Mmu _mmu = Mmu();

  late final Cpu _cpu;

  late final Timer _timer = Timer(_interruptManager, _speedMode);

  late final Dma _dma;

  late final Hdma _hdma;

  final Display _display;

  late final Sound _sound;

  late final SerialPort _serialPort;

  late final bool _gbc;

  final SpeedMode _speedMode = SpeedMode();

  bool _doStop = false;

  // final List<Runnable> _tickListeners = [];

  Gameboy(
    GameboyOptions options,
    Cartridge rom,
    this._display,
    Controller controller,
    SoundOutput soundOutput,
    SerialEndpoint serialEndpoint,
  ) {
    _gbc = rom.isGbc();
    Ram oamRam = Ram(0xfe00, 0x00a0);
    _dma = Dma(_mmu, oamRam, _speedMode);
    _gpu = Gpu(_display, _interruptManager, _dma, oamRam, _gbc);
    _hdma = Hdma(_mmu);
    _sound = Sound(soundOutput, _gbc);
    _serialPort = SerialPort(_interruptManager, serialEndpoint, _speedMode);
    _mmu.addAddressSpace(rom);
    _mmu.addAddressSpace(_gpu);
    _mmu.addAddressSpace(Joypad(_interruptManager, controller));
    _mmu.addAddressSpace(_interruptManager);
    _mmu.addAddressSpace(_serialPort);
    _mmu.addAddressSpace(_timer);
    _mmu.addAddressSpace(_dma);
    _mmu.addAddressSpace(_sound);

    _mmu.addAddressSpace(Ram(0xc000, 0x1000));
    if (_gbc) {
      _mmu.addAddressSpace(_speedMode);
      _mmu.addAddressSpace(_hdma);
      _mmu.addAddressSpace(GbcRam());
      _mmu.addAddressSpace(UndocumentedGbcRegisters());
    } else {
      _mmu.addAddressSpace(Ram(0xd000, 0x1000));
    }
    _mmu.addAddressSpace(Ram(0xff80, 0x7f));
    _mmu.addAddressSpace(ShadowAddressSpace(_mmu, 0xe000, 0xc000, 0x1e00));

    _cpu = Cpu(_mmu, _interruptManager, _gpu, _display, _speedMode);

    _interruptManager.disableInterrupts(false);
    if (!options.useBootstrap) {
      initRegs();
    }
  }

  void initRegs() {
    Registers r = _cpu.getRegisters();

    r.af = 0x01b0;
    if (_gbc) {
      r.a = 0x11;
    }
    r.bc = (0x0013);
    r.de = (0x00d8);
    r.hl = (0x014d);
    r.sp = (0xfffe);
    r.pc = (0x0100);
  }

  void run() {
    bool requestedScreenRefresh = false;
    bool lcdDisabled = false;
    _doStop = false;
    while (!_doStop) {
      GpuMode? newMode = tick();
      if (newMode != null) {
        _hdma.onGpuUpdate(newMode);
      }

      if (!lcdDisabled && !_gpu.lcdEnabled) {
        lcdDisabled = true;
        _display.requestRefresh();
        _hdma.onLcdSwitch(false);
      } else if (newMode == GpuMode.vBlank) {
        requestedScreenRefresh = true;
        _display.requestRefresh();
      }

      if (lcdDisabled && _gpu.lcdEnabled) {
        lcdDisabled = false;
        _display.waitForRefresh();
        _hdma.onLcdSwitch(true);
      } else if (requestedScreenRefresh && newMode == GpuMode.oamSearch) {
        requestedScreenRefresh = false;
        _display.waitForRefresh();
      }
      // console.ifPresent(Console::tick);
      // tickListeners.forEach(Runnable::run);
    }
  }

  void stop() {
    _doStop = true;
  }

  GpuMode? tick() {
    _timer.tick();
    if (_hdma.isTransferInProgress()) {
      _hdma.tick();
    } else {
      _cpu.tick();
    }
    _dma.tick();
    _sound.tick();
    _serialPort.tick();
    return _gpu.tick();
  }

  AddressSpace getAddressSpace() {
    return _mmu;
  }

  Cpu getCpu() {
    return _cpu;
  }

  SpeedMode getSpeedMode() {
    return _speedMode;
  }

  Gpu getGpu() {
    return _gpu;
  }

/*
  void registerTickListener(Runnable tickListener) {
    tickListeners.add(tickListener);
  }

  void unregisterTickListener(Runnable tickListener) {
    tickListeners.remove(tickListener);
  }
*/
  Sound getSound() {
    return _sound;
  }
}
