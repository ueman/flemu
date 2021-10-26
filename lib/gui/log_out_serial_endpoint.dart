import 'dart:developer';

import 'package:gb_emulator/serial/serial_endpoint.dart';

class SystemOutSerialEndpoint implements SerialEndpoint {
  @override
  int transfer(int b) {
    log(String.fromCharCode(b));
    return 0;
  }
}
