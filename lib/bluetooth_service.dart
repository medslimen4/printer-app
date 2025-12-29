
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

  /// Connects to the device, discovers all services and characteristics,
  /// and prints them to the console for debugging purposes.
  Future<void> discoverAndLogServices(BluetoothDevice device) async {
    if (kDebugMode) {
      print('Discovering services for ${device.remoteId}...');
    }
    try {
      List<BluetoothService> services = await device.discoverServices();
      print('==================================================');
      print('FOUND ${services.length} SERVICES');
      print('==================================================');
      for (var service in services) {
        print('Service UUID: ${service.uuid}');
        print('  Characteristics:');
        for (var characteristic in service.characteristics) {
          print('  - Char UUID: ${characteristic.uuid}');
          print('    Properties:');
          print('      Read: ${characteristic.properties.read}');
          print('      Write: ${characteristic.properties.write}');
          print('      Notify: ${characteristic.properties.notify}');
          print('      Indicate: ${characteristic.properties.indicate}');
        }
        print('--------------------------------------------------');
      }
      print('==================================================');

    } catch (e) {
      if (kDebugMode) {
        print('Error discovering services: $e');
      }
    }
  }

  Future<void> sendData(BluetoothDevice device, String serviceUuid,
      String characteristicUuid, List<int> data) async {
    // We will discover services again here to be safe
    List<BluetoothService> services = await device.discoverServices();
    var service = services.firstWhere((s) => s.uuid.toString() == serviceUuid);
    var characteristic =
        service.characteristics.firstWhere((c) => c.uuid.toString() == characteristicUuid);
    
    if (kDebugMode) {
      print('Writing to characteristic ${characteristic.uuid}');
    }
    await characteristic.write(data);
  }
}
