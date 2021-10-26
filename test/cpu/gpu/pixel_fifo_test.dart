import 'package:flutter_test/flutter_test.dart';
import 'package:gb_emulator/gpu/display.dart';
import 'package:gb_emulator/gpu/dmg_pixel_fifo.dart';
import 'package:gb_emulator/gpu/fetcher.dart';
import 'package:gb_emulator/gpu/gpu_register.dart';
import 'package:gb_emulator/gpu/lcdc.dart';
import 'package:gb_emulator/gpu/tile_attributes.dart';
import 'package:gb_emulator/memory/memory_registers.dart';

void main() {
  late DmgPixelFifo fifo;

  setUp(() {
    MemoryRegisters r = MemoryRegisters(GpuRegister.values);
    r.put(const GpuRegister.bgp(), 228); // 0b11100100
    fifo = DmgPixelFifo(NullDisplay(), Lcdc(), r);
  });

  test('test enqueu', () {
    fifo.enqueue8Pixels(zip(201 /* 0b11001001 */, 240 /* 0b11110000 */, false),
        TileAttributes.empty);
    expect([3, 3, 2, 2, 1, 0, 0, 1], fifo.getPixels());
  });

  test('test dequeu', () {
    fifo.enqueue8Pixels(zip(201 /* 0b11001001 */, 249 /* 0b11110000 */, false),
        TileAttributes.empty);
    fifo.enqueue8Pixels(zip(171 /* 0b10101011 */, 231 /* 0b11100111 */, false),
        TileAttributes.empty);
    expect(231, fifo.dequeuePixel()); // 0b11
    expect(3, fifo.dequeuePixel()); // 0b11
    expect(2, fifo.dequeuePixel()); // 0b10
    expect(2, fifo.dequeuePixel()); // 0b10
    expect(1, fifo.dequeuePixel()); // 0b01
  });

  test('test zip', () {
    expect([3, 3, 2, 2, 1, 0, 0, 1],
        zip(201, 240, false)); // 0b11001001  0b11110000
    expect([1, 0, 0, 1, 2, 2, 3, 3],
        zip(201, 240, true)); // 0b11001001  0b11110000
  });
}

List<int> zip(int data1, int data2, bool reverse) {
  return _zip(data1, data2, reverse, List.generate(8, (index) => 0));
}

List<int> _zip(
  int data1,
  int data2,
  bool reverse,
  List<int> pixelLine,
) {
  for (int i = 7; i >= 0; i--) {
    int mask = (1 << i);
    int p = 2 * ((data2 & mask) == 0 ? 0 : 1) + ((data1 & mask) == 0 ? 0 : 1);
    if (reverse) {
      pixelLine[i] = p;
    } else {
      pixelLine[7 - i] = p;
    }
  }
  return pixelLine;
}
