import 'package:gb_emulator/gpu/display.dart';
import 'package:gb_emulator/gpu/gpu_register.dart';
import 'package:gb_emulator/gpu/int_queue.dart';
import 'package:gb_emulator/gpu/lcdc.dart';
import 'package:gb_emulator/gpu/pixel_fifo.dart';
import 'package:gb_emulator/gpu/tile_attributes.dart';
import 'package:gb_emulator/memory/memory_registers.dart';

class DmgPixelFifo implements PixelFifo {
  final IntQueue _pixels = IntQueue(16);

  final IntQueue _palettes = IntQueue(16);

  final IntQueue _pixelType = IntQueue(16); // 0 - bg, 1 - sprite

  final Display _display;

  final Lcdc _lcdc;

  final MemoryRegisters _registers;

  DmgPixelFifo(this._display, this._lcdc, this._registers);

  @override
  int getLength() {
    return _pixels.size();
  }

  @override
  void putPixelToScreen() {
    _display.putDmgPixel(dequeuePixel());
  }

  @override
  void dropPixel() {
    dequeuePixel();
  }

  int dequeuePixel() {
    _pixelType.dequeue();
    return _getColor(_palettes.dequeue(), _pixels.dequeue());
  }

  @override
  void enqueue8Pixels(List<int> pixelLine, TileAttributes tileAttributes) {
    for (int p in pixelLine) {
      _pixels.enqueue(p);
      _palettes.enqueue(_registers.get(const GpuRegister.bgp()));
      _pixelType.enqueue(0);
    }
  }

  @override
  void setOverlay(
      List<int> pixelLine, int offset, TileAttributes flags, int oamIndex) {
    bool priority = flags.isPriority();
    int overlayPalette = _registers.get(flags.getDmgPalette());

    for (int j = offset; j < pixelLine.length; j++) {
      int p = pixelLine[j];
      int i = j - offset;
      if (_pixelType.get(i) == 1) {
        continue;
      }
      if ((priority && _pixels.get(i) == 0) || !priority && p != 0) {
        _pixels.set(i, p);
        _palettes.set(i, overlayPalette);
        _pixelType.set(i, 1);
      }
    }
  }

  IntQueue getPixels() {
    return _pixels;
  }

  static int _getColor(int palette, int colorIndex) {
    return 3 /* 0b11 */ & (palette >> (colorIndex * 2));
  }

  @override
  void clear() {
    _pixels.clear();
    _palettes.clear();
    _pixelType.clear();
  }
}
