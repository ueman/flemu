import 'package:gb_emulator/gpu/color_palette.dart';
import 'package:gb_emulator/gpu/display.dart';
import 'package:gb_emulator/gpu/int_queue.dart';
import 'package:gb_emulator/gpu/lcdc.dart';
import 'package:gb_emulator/gpu/pixel_fifo.dart';
import 'package:gb_emulator/gpu/tile_attributes.dart';

class ColorPixelFifo implements PixelFifo {
  final IntQueue _pixels = IntQueue(16);

  final IntQueue _palettes = IntQueue(16);

  final IntQueue _priorities = IntQueue(16);

  final Lcdc _lcdc;

  final Display _display;

  final ColorPalette _bgPalette;

  final ColorPalette _oamPalette;

  ColorPixelFifo(this._lcdc, this._display, this._bgPalette, this._oamPalette);

  @override
  int getLength() {
    return _pixels.size();
  }

  @override
  void putPixelToScreen() {
    _display.putColorPixel(_dequeuePixel());
  }

  int _dequeuePixel() {
    return getColor(
        _priorities.dequeue(), _palettes.dequeue(), _pixels.dequeue());
  }

  @override
  void dropPixel() {
    _dequeuePixel();
  }

  @override
  void enqueue8Pixels(List<int> pixelLine, TileAttributes tileAttributes) {
    for (int p in pixelLine) {
      _pixels.enqueue(p);
      _palettes.enqueue(tileAttributes.getColorPaletteIndex());
      _priorities.enqueue(tileAttributes.isPriority() ? 100 : -1);
    }
  }

  /*
    lcdc.0
    when 0 => sprites are always displayed on top of the bg
    bg tile attribute.7
    when 0 => use oam priority bit
    when 1 => bg priority
    sprite attribute.7
    when 0 => sprite above bg
    when 1 => sprite above bg color 0
     */
  @override
  void setOverlay(List<int> pixelLine, int offset, TileAttributes spriteAttr,
      int oamIndex) {
    for (int j = offset; j < pixelLine.length; j++) {
      int p = pixelLine[j];
      int i = j - offset;
      if (p == 0) {
        continue; // color 0 is always transparent
      }
      int oldPriority = _priorities.get(i);

      bool put = false;
      if ((oldPriority == -1 || oldPriority == 100) &&
          !_lcdc.isBgAndWindowDisplay()) {
        // this one takes precedence
        put = true;
      } else if (oldPriority == 100) {
        // bg with priority
        put = _pixels.get(i) == 0;
      } else if (oldPriority == -1 && !spriteAttr.isPriority()) {
        // bg without priority
        put = true;
      } else if (oldPriority == -1 &&
          spriteAttr.isPriority() &&
          _pixels.get(i) == 0) {
        // bg without priority
        put = true;
      } else if (oldPriority >= 0 && oldPriority < 10) {
        // other sprite
        put = oldPriority > oamIndex;
      }

      if (put) {
        _pixels.set(i, p);
        _palettes.set(i, spriteAttr.getColorPaletteIndex());
        _priorities.set(i, oamIndex);
      }
    }
  }

  @override
  void clear() {
    _pixels.clear();
    _palettes.clear();
    _priorities.clear();
  }

  int getColor(int priority, int palette, int color) {
    if (priority >= 0 && priority < 10) {
      return _oamPalette.getPalette(palette)[color];
    } else {
      return _bgPalette.getPalette(palette)[color];
    }
  }
}
