abstract class SerialEndpoint {
  SerialEndpoint();
  factory SerialEndpoint.nullEndpoint() => _NullEndpoint();

  int transfer(int outgoing);
}

class _NullEndpoint extends SerialEndpoint {
  @override
  int transfer(int outgoing) {
    return 0;
  }
}
