
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AppBluetoothService {
  Future<void> connect(BluetoothDevice device) async {
    await _requestPermissions();
    await device.connect();
  }

  Future<void> disconnect(BluetoothDevice device) async {
    await device.disconnect();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> sendData(BluetoothDevice device, String serviceUuid,
      String characteristicUuid, List<int> data) async {
    List<BluetoothService> services = await device.discoverServices();
    var service = services.firstWhere((s) => s.uuid.toString() == serviceUuid);
    var characteristic =
        service.characteristics.firstWhere((c) => c.uuid.toString() == characteristicUuid);
    await characteristic.write(data);
  }
}
