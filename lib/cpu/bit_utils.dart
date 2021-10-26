int toWordFromList(List<int> bytes) {
  return toWord(bytes[1], bytes[0]);
}

int toWord(int msb, int lsb) {
  assertIsByte("msb", msb);
  assertIsByte("lsb", lsb);
  return (msb << 8) | lsb;
}

int toSigned(int byteValue) {
  if ((byteValue & (1 << 7)) == 0) {
    return byteValue;
  } else {
    return byteValue - 0x100;
  }
}

int getMSB(int word) {
  assertIsWordArgument("word", word);
  return word >> 8;
}

int getLSB(int word) {
  assertIsWordArgument("word", word);
  return word & 0xff;
}

bool getBit(int byteValue, int position) {
  return (byteValue & (1 << position)) != 0;
}

int setBit(int byteValue, int position, [bool? value]) {
  if (value == null) {
    assertIsByte("byteValue", byteValue);
    return (byteValue | (1 << position)) & 0xff;
  }
  return value ? setBit(byteValue, position) : clearBit(byteValue, position);
}

int clearBit(int byteValue, int position) {
  assertIsByte("byteValue", byteValue);
  return ~(1 << position) & byteValue & 0xff;
}

void assertIsByte(String argumentName, int argument) {
  assert(
    argument >= 0 && argument <= 0xff,
    "Argument $argumentName should be a byte",
  );
}

void assertIsWordArgument(String argumentName, int argument) {
  assert(
    argument >= 0 && argument <= 0xffff,
    "Argument $argumentName should be a word",
  );
}
