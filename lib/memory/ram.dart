import 'package:gb_emulator/address_space.dart';

class Ram implements AddressSpace {
  List<int> space;

  final int _length;

  final int _offset;

  Ram(this._offset, this._length)
      : space = List.generate(_length, (index) => 0);

  Ram.createShadow(this._offset, this._length, Ram ram) : space = ram.space;

  @override
  bool accepts(int address) {
    return address >= _offset && address < _offset + _length;
  }

  @override
  void setByte(int address, int value) {
    space[address - _offset] = value;
  }

  @override
  int getByte(int address) {
    int index = address - _offset;
    if (index < 0 || index >= space.length) {
      throw Exception("Address: address");
    }
    return space[index];
  }
}
