import 'package:flutter_test/flutter_test.dart';
import 'package:gb_emulator/gpu/color_palette.dart';
import 'package:gb_emulator/int_x.dart';

void main() {
  test('test auto increment', () {
    ColorPalette p = ColorPalette(0xff68);
    p.setByte(0xff68, 0x80);
    p.setByte(0xff69, 0x00);
    p.setByte(0xff69, 0xaa);
    p.setByte(0xff69, 0x11);
    p.setByte(0xff69, 0xbb);
    p.setByte(0xff69, 0x22);
    p.setByte(0xff69, 0xcc);
    p.setByte(0xff69, 0x33);
    p.setByte(0xff69, 0xdd);
    p.setByte(0xff69, 0x44);
    p.setByte(0xff69, 0xee);
    p.setByte(0xff69, 0x55);
    p.setByte(0xff69, 0xff);
    assertArrayEquals([0xaa00, 0xbb11, 0xcc22, 0xdd33], p.getPalette(0));
    assertArrayEquals([0xee44, 0xff55, 0x0000, 0x0000], p.getPalette(1));
  });
}

void assertArrayEquals(List<int> expected, List<int> actual) {
  expect(expected.length, actual.length);
  for (int i = 0; i < expected.length; i++) {
    if (expected[i] != actual[i]) {
      fail(
        "arrays first differed at element [$i]\n"
        "Expected :${expected[i].toHex()}\n"
        "Actual   :${actual[i]}",
      );
    }
  }
}
