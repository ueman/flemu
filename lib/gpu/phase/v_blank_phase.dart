import 'package:gb_emulator/gpu/phase/gpu_phase.dart';

class VBlankPhase implements GpuPhase {
  int _ticks = 0;

  VBlankPhase start() {
    _ticks = 0;
    return this;
  }

  @override
  bool tick() {
    return ++_ticks < 456;
  }
}
