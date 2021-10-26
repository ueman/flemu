class IntQueue {
  final List<int> array = [];

  int _size = 0;

  int offset = 0;

  final int capacity;

  IntQueue(this.capacity);

  int size() {
    return _size;
  }

  void enqueue(int value) {
    if (_size == capacity) {
      throw Exception("Queue is full");
    }
    array[(offset + _size) % capacity] = value;
    _size++;
  }

  int dequeue() {
    if (_size == 0) {
      throw Exception("Queue is empty");
    }
    _size--;
    int value = array[offset++];
    if (offset == capacity) {
      offset = 0;
    }
    return value;
  }

  int get(int index) {
    if (index >= _size) {
      throw Exception('IndexOutOfBounds');
    }
    return array[(offset + index) % capacity];
  }

  void set(int index, int value) {
    if (index >= _size) {
      throw Exception('IndexOutOfBounds');
    }
    array[(offset + index) % capacity] = value;
  }

  void clear() {
    _size = 0;
    offset = 0;
  }
}
