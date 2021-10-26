import 'package:gb_emulator/memory/cart/rtc/clock.dart';

int _rtcClockStart() => DateTime.now().millisecondsSinceEpoch;

class RealTimeClock {
  final Clock _clock;

  int _offsetSec = 0;

  late int _clockStart = _rtcClockStart();

  bool _halt = false;

  int _latchStart = 0;

  int _haltSeconds = 0;

  int _haltMinutes = 0;

  int _haltHours = 0;

  int _haltDays = 0;

  RealTimeClock(this._clock);

  void latch() {
    _latchStart = _clock.currentTimeMillis();
  }

  void unlatch() {
    _latchStart = 0;
  }

  int getSeconds() {
    return (clockTimeInSec() % 60);
  }

  int getMinutes() {
    return ((clockTimeInSec() % (60 * 60)) ~/ 60);
  }

  int getHours() {
    return ((clockTimeInSec() % (60 * 60 * 24)) ~/ (60 * 60));
  }

  int getDayCounter() {
    return (clockTimeInSec() % (60 * 60 * 24 * 512) ~/ (60 * 60 * 24));
  }

  bool isHalt() {
    return _halt;
  }

  bool isCounterOverflow() {
    return clockTimeInSec() >= 60 * 60 * 24 * 512;
  }

  void setSeconds(int seconds) {
    if (!_halt) {
      return;
    }
    _haltSeconds = seconds;
  }

  void setMinutes(int minutes) {
    if (!_halt) {
      return;
    }
    _haltMinutes = minutes;
  }

  void setHours(int hours) {
    if (!_halt) {
      return;
    }
    _haltHours = hours;
  }

  void setDayCounter(int dayCounter) {
    if (!_halt) {
      return;
    }
    _haltDays = dayCounter;
  }

  void setHalt(bool halt) {
    if (halt && !_halt) {
      latch();
      _haltSeconds = getSeconds();
      _haltMinutes = getMinutes();
      _haltHours = getHours();
      _haltDays = getDayCounter();
      unlatch();
    } else if (!halt && _halt) {
      _offsetSec = _haltSeconds +
          _haltMinutes * 60 +
          _haltHours * 60 * 60 +
          _haltDays * 60 * 60 * 24;
      _clockStart = _clock.currentTimeMillis();
    }
    _halt = halt;
  }

  void clearCounterOverflow() {
    while (isCounterOverflow()) {
      _offsetSec -= 60 * 60 * 24 * 512;
    }
  }

  int clockTimeInSec() {
    int now;
    if (_latchStart == 0) {
      now = _clock.currentTimeMillis();
    } else {
      now = _latchStart;
    }
    return ((now - _clockStart) / 1000 + _offsetSec).toInt();
  }

  void deserialize(List<int> clockData) {
    var seconds = clockData[0];
    var minutes = clockData[1];
    var hours = clockData[2];
    var days = clockData[3];
    var daysHigh = clockData[4];
    var timestamp = clockData[10];

    _clockStart = timestamp * 1000;
    _offsetSec = seconds +
        minutes * 60 +
        hours * 60 * 60 +
        days * 24 * 60 * 60 +
        daysHigh * 256 * 24 * 60 * 60;
  }

  List<int> serialize() {
    var clockData = <int>[]; // 11
    latch();
    clockData[0] = clockData[5] = getSeconds();
    clockData[1] = clockData[6] = getMinutes();
    clockData[2] = clockData[7] = getHours();
    clockData[3] = clockData[8] = getDayCounter() % 256;
    clockData[4] = clockData[9] = getDayCounter() ~/ 256;
    clockData[10] = _latchStart ~/ 1000;
    unlatch();
    return clockData;
  }
}
