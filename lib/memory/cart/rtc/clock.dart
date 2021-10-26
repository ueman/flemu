abstract class Clock {
  int currentTimeMillis();
}

class SystemClock extends Clock {
  @override
  int currentTimeMillis() => DateTime.now().millisecondsSinceEpoch;
}
