abstract class Display {
  void putDmgPixel(int color);

  void putColorPixel(int gbcRgb);

  void requestRefresh();

  void waitForRefresh();

  void enableLcd();

  void disableLcd();
}

class NullDisplay extends Display {
  @override
  void disableLcd() {}

  @override
  void enableLcd() {}

  @override
  void putColorPixel(int gbcRgb) {}

  @override
  void putDmgPixel(int color) {}

  @override
  void requestRefresh() {}

  @override
  void waitForRefresh() {}
}
