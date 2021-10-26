abstract class AddressSpace {
  bool accepts(int address);

  void setByte(int address, int value);

  int getByte(int address);
}
