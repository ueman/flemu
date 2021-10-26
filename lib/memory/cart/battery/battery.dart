abstract class Battery {
  void loadRam(List<int> ram);

  void saveRam(List<int> ram);

  void loadRamWithClock(List<int> ram, List<int> clockData);

  void saveRamWithClock(List<int> ram, List<int> clockData);
}

class NullBattery extends Battery {
  @override
  void loadRam(List<int> ram) {}

  @override
  void loadRamWithClock(List<int> ram, List<int> clockData) {}

  @override
  void saveRam(List<int> ram) {}

  @override
  void saveRamWithClock(List<int> ram, List<int> clockData) {}
}
