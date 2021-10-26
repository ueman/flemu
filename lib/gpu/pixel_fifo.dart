import 'package:gb_emulator/gpu/tile_attributes.dart';

abstract class PixelFifo {
  int getLength();

  void putPixelToScreen();

  void dropPixel();

  void enqueue8Pixels(List<int> pixels, TileAttributes tileAttributes);

  void setOverlay(
    List<int> pixelLine,
    int offset,
    TileAttributes flags,
    int oamIndex,
  );

  void clear();
}
