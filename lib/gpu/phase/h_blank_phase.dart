import 'package:gb_emulator/gpu/phase/gpu_phase.dart';

class HBlankPhase implements GpuPhase {
  int _ticks = 0;

  HBlankPhase start(int ticksInLine) {
    _ticks = ticksInLine;
    return this;
  }

  @override
  bool tick() {
    _ticks++;
    return _ticks < 456;
  }
}
