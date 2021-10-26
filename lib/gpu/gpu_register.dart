import 'package:gb_emulator/memory/memory_registers.dart';

class GpuRegister implements Register {
  const GpuRegister.STAT()
      : address = 0xff41,
        type = const RegisterType.rw();
  const GpuRegister.SCY()
      : address = 0xff42,
        type = const RegisterType.rw();
  const GpuRegister.SCX()
      : address = 0xff43,
        type = const RegisterType.rw();
  const GpuRegister.LY()
      : address = 0xff44,
        type = const RegisterType.r();
  const GpuRegister.LYC()
      : address = 0xff45,
        type = const RegisterType.rw();
  const GpuRegister.BGP()
      : address = 0xff47,
        type = const RegisterType.rw();
  const GpuRegister.OBP0()
      : address = 0xff48,
        type = const RegisterType.rw();
  const GpuRegister.OBP1()
      : address = 0xff49,
        type = const RegisterType.rw();
  const GpuRegister.WY()
      : address = 0xff4a,
        type = const RegisterType.rw();
  const GpuRegister.WX()
      : address = 0xff4b,
        type = const RegisterType.rw();
  const GpuRegister.VBK()
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
    GpuRegister.STAT(),
    GpuRegister.SCY(),
    GpuRegister.SCX(),
    GpuRegister.LY(),
    GpuRegister.LYC(),
    GpuRegister.BGP(),
    GpuRegister.OBP0(),
    GpuRegister.OBP1(),
    GpuRegister.WY(),
    GpuRegister.WX(),
    GpuRegister.VBK(),
  ];
}
