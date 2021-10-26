import 'dart:io';

import 'package:gb_emulator/memory/cart/battery/battery.dart';
/*
class FileBattery implements Battery {

    final File saveFile;

    FileBattery(this.saveFile);

    @override
    void loadRam(List<int> ram) => loadRamWithClock(ram, null);

    @override
    void saveRam(List<int> ram) => saveRamWithClock(ram, null);

    @override
    void loadRamWithClock(List<int> ram, List<int>? clockData) {
        if (!saveFile.existsSync()) {
            return;
        }
        int saveLength = saveFile.lengthSync();
        saveLength = saveLength - (saveLength % 0x2000);
        final intList = List.from(saveFile.readAsBytesSync());
        
        _loadRam(ram, intList, saveLength);
        if (clockData != null) {
            _loadClock(clockData, intList);
        }
    }

    @override
    void saveRamWithClock(List<int> ram, List<int>? clockData) {
        _saveRam(ram, saveFile);
        if (clockData != null) {
            _saveClock(clockData, saveFile);
        }
    }

    void _loadClock(List<int> clockData, List<int> is) {
        List<int> byteBuff = []; // new byte[4 * clockData.length];
        IOUtils.read(is, byteBuff);
        ByteBuffer buff = ByteBuffer.wrap(byteBuff);
        buff.order(ByteOrder.LITTLE_ENDIAN);
        int i = 0;
        while (buff.hasRemaining()) {
            clockData[i++] = buff.getInt() & 0xffffffff;
        }
    }

    void _saveClock(List<int> clockData, OutputStream os) {
        byte[] byteBuff = new byte[4 * clockData.length];
        ByteBuffer buff = ByteBuffer.wrap(byteBuff);
        buff.order(ByteOrder.LITTLE_ENDIAN);
        for (long d : clockData) {
            buff.putInt((int) d);
        }
        IOUtils.write(byteBuff, os);
    }

    void _loadRam(List<int> ram, List<int> is, long length){
        byte[] buffer = new byte[ram.length];
        IOUtils.read(is, buffer, 0, Math.min((int) length, ram.length));
        for (int i = 0; i < ram.length; i++) {
            ram[i] = buffer[i] & 0xff;
        }
    }

    void _saveRam(List<int> ram, File os)  {
        byte[] buffer = new byte[ram.length];
        for (int i = 0; i < ram.length; i++) {
            buffer[i] = (byte) (ram[i]);
        }
        IOUtils.write(buffer, os);
    }
}
*/