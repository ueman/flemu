import 'package:gb_emulator/memory/cart/rtc/clock.dart';

int _rtcClockStart() => DateTime.now().millisecondsSinceEpoch;

class VirtualClock implements Clock {
  late int _clock = _rtcClockStart();

  @override
  int currentTimeMillis() => _clock;

  void forward(int i, Duration unit) {
    _clock += unit.inMilliseconds * i;
  }
}
