import 'package:gb_emulator/memory/memory_registers.dart';

class GpuRegister implements Register {
  const GpuRegister.stat()
      : address = 0xff41,
        type = const RegisterType.rw();
  const GpuRegister.scy()
      : address = 0xff42,
        type = const RegisterType.rw();
  const GpuRegister.scx()
      : address = 0xff43,
        type = const RegisterType.rw();
  const GpuRegister.ly()
      : address = 0xff44,
        type = const RegisterType.r();
  const GpuRegister.lyc()
      : address = 0xff45,
        type = const RegisterType.rw();
  const GpuRegister.bgp()
      : address = 0xff47,
        type = const RegisterType.rw();
  const GpuRegister.obp0()
      : address = 0xff48,
        type = const RegisterType.rw();
  const GpuRegister.obp1()
      : address = 0xff49,
        type = const RegisterType.rw();
  const GpuRegister.wy()
      : address = 0xff4a,
        type = const RegisterType.rw();
  const GpuRegister.wx()
      : address = 0xff4b,
        type = const RegisterType.rw();
  const GpuRegister.vbk()
      : address = 0xff4f,
        type = const RegisterType.w();

  final int address;

  final RegisterType type;

  @override
  int getAddress() {
    return address;
  }

  @override
  RegisterType getType() {
    return type;
  }

  static const values = [
    GpuRegister.stat(),
    GpuRegister.scy(),
    GpuRegister.scx(),
    GpuRegister.ly(),
    GpuRegister.lyc(),
    GpuRegister.bgp(),
    GpuRegister.obp0(),
    GpuRegister.obp1(),
    GpuRegister.wy(),
    GpuRegister.wx(),
    GpuRegister.vbk(),
  ];
}
