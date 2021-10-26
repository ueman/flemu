import 'dart:io';

class GameboyOptions {
  GameboyOptions({
    required this.romFile,
    required this.forceDmg,
    required this.forceCgb,
    required this.useBootstrap,
    required this.disableBatterySaves,
    required this.debug,
    required this.headless,
  });

  final File romFile;
  final bool forceDmg;
  final bool forceCgb;
  final bool useBootstrap;
  final bool disableBatterySaves;
  bool get isSupportBatterySaves => !disableBatterySaves;
  final bool debug;
  final bool headless;
}
