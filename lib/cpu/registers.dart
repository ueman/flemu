import 'package:gb_emulator/cpu/bit_utils.dart';
import 'package:gb_emulator/cpu/flags.dart';
import 'package:gb_emulator/int_x.dart';

class Registers {
  int _a = 0;
  set a(int value) {
    assertIsByte('a', value);
    _a = value;
  }

  int get a => _a;

  int _b = 0;
  set b(int value) {
    assertIsByte('b', value);
    _b = value;
  }

  int get b => _b;

  int _c = 0;
  set c(int value) {
    assertIsByte('c', value);
    _c = value;
  }

  int get c => _c;

  int _d = 0;
  set d(int value) {
    assertIsByte('d', value);
    _d = value;
  }

  int get d => _d;

  int _e = 0;
  set e(int value) {
    assertIsByte('e', value);
    _e = value;
  }

  int get e => _e;

  int _h = 0;
  set h(int value) {
    assertIsByte('h', value);
    _h = value;
  }

  int get h => _h;

  int _l = 0;
  set l(int value) {
    assertIsByte('l', value);
    _l = value;
  }

  int get l => _l;

  Flags flags = Flags();

  set af(int af) {
    assertIsWordArgument("af", af);
    a = getMSB(af);
    flags.setFlagsByte(getLSB(af));
  }

  int get af => a << 8 | flags.flagsByte;

  int get bc => b << 8 | c;

  int get de => d << 8 | e;

  int get hl => h << 8 | l;

  set bc(int value) {
    assertIsWordArgument("bc", value);
    b = getMSB(value);
    c = getLSB(value);
  }

  set de(int value) {
    assertIsWordArgument("de", value);
    d = getMSB(value);
    e = getLSB(value);
  }

  set hl(int value) {
    assertIsWordArgument("hl", value);
    h = getMSB(value);
    l = getLSB(value);
  }

  int _sp = 0;
  int get sp => _sp;
  set sp(int value) {
    assertIsWordArgument("sp", value);
    _sp = value;
  }

  int _pc = 0;
  int get pc => _pc;
  set pc(int value) {
    assertIsWordArgument("pc", value);
    _pc = value;
  }

  void incrementPC() {
    pc = (pc + 1) & 0xffff;
  }

  void decrementSP() {
    sp = (sp - 1) & 0xffff;
  }

  void incrementSP() {
    sp = (sp + 1) & 0xffff;
  }

  @override
  String toString() {
    return 'AF=${af.toHex()}, '
        'BC=${bc.toHex()}, '
        'DE=${de.toHex()}, '
        'HL=${hl.toHex()}, '
        'SP=${sp.toHex()}, '
        'PC=${pc.toHex()}, '
        '$flags';
  }
}
