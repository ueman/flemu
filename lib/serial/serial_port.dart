import 'package:gb_emulator/address_space.dart';
import 'package:gb_emulator/cpu/interrupt_manager.dart';
import 'package:gb_emulator/cpu/speed_mode.dart';
import 'package:gb_emulator/gameboy.dart';
import 'package:gb_emulator/serial/serial_endpoint.dart';

class SerialPort implements AddressSpace {
  //final Logger _LOG = LoggerFactory.getLogger(SerialPort.class);

  final SerialEndpoint _serialEndpoint;
  final InterruptManager _interruptManager;
  final SpeedMode _speedMode;
  int _sb = 0;
  int _sc = 0;
  bool _transferInProgress = false;
  int _divider = 0;

  SerialPort(
    this._interruptManager,
    this._serialEndpoint,
    this._speedMode,
  );

  void tick() {
    if (!_transferInProgress) {
      return;
    }
    if (++_divider >= ticksPerSecond / 8192 / _speedMode.getSpeedMode()) {
      _transferInProgress = false;
      try {
        _sb = _serialEndpoint.transfer(_sb);
      } catch (e) {
        //LOG.error("Can't transfer byte", e);
        _sb = 0;
      }
      _interruptManager.requestInterrupt(const InterruptType.serial());
    }
  }

  @override
  bool accepts(int address) {
    return address == 0xff01 || address == 0xff02;
  }

  @override
  void setByte(int address, int value) {
    if (address == 0xff01) {
      _sb = value;
    } else if (address == 0xff02) {
      _sc = value;
      if ((_sc & (1 << 7)) != 0) {
        startTransfer();
      }
    }
  }

  @override
  int getByte(int address) {
    if (address == 0xff01) {
      return _sb;
    } else if (address == 0xff02) {
      return _sc | 126; // 0b01111110
    } else {
      throw Exception('invalid argument');
    }
  }

  void startTransfer() {
    _transferInProgress = true;
    _divider = 0;
  }
}
