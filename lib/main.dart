
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:myapp/bluetooth_service.dart';
import 'package:myapp/command_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rongta Wi-Fi Setter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final BluetoothService _bluetoothService = BluetoothService();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  BluetoothDevice? _selectedDevice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rongta Wi-Fi Setter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                _bluetoothService.startScan();
                _showDeviceSelectionDialog();
              },
              child: const Text('Scan for Devices'),
            ),
            if (_selectedDevice != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text('Selected Device: ${_selectedDevice!.name}'),
              ),
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(labelText: 'SSID'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendWifiCredentials,
              child: const Text('Send Wi-Fi Credentials'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeviceSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Device'),
          content: StreamBuilder<List<ScanResult>>(
            stream: _bluetoothService.scanResults,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final device = snapshot.data![index].device;
                    return ListTile(
                      title: Text(device.name.isNotEmpty ? device.name : 'Unknown Device'),
                      subtitle: Text(device.remoteId.toString()),
                      onTap: () {
                        setState(() {
                          _selectedDevice = device;
                        });
                        Navigator.of(context).pop();
                        _bluetoothService.stopScan();
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _sendWifiCredentials() async {
    if (_selectedDevice == null) {
      _showErrorDialog('No device selected.');
      return;
    }

    final ssid = _ssidController.text;
    final password = _passwordController.text;

    if (ssid.isEmpty || password.isEmpty) {
      _showErrorDialog('SSID and password cannot be empty.');
      return;
    }

    try {
      await _bluetoothService.connect(_selectedDevice!);

      // These UUIDs are placeholders and need to be found from the sniffing log.
      const serviceUuid = '00001800-0000-1000-8000-00805f9b34fb';
      const characteristicUuid = '00002a00-0000-1000-8000-00805f9b34fb';

      final command = CommandBuilder.buildWifiCommand(ssid, password);
      await _bluetoothService.sendData(_selectedDevice!, serviceUuid, characteristicUuid, command);

      await _bluetoothService.disconnect(_selectedDevice!);

      _showSuccessDialog('Wi-Fi credentials sent successfully!');
    } catch (e) {
      _showErrorDialog('Error sending credentials: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
