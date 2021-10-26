abstract class SoundOutput {
  void start();

  void stop();

  void play(int left, int right);
}

class NullOutput extends SoundOutput {
  @override
  void start() {}

  @override
  void stop() {}

  @override
  void play(int left, int right) {}
}
