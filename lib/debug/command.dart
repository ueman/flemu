import 'package:gb_emulator/debug/command_pattern.dart';

abstract class Command {
  CommandPattern getPattern();

  void run(ParsedCommandLine commandLine);
}
