
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
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
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
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
  final AppBluetoothService _bluetoothService = AppBluetoothService();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Connect directly to the printer using its MAC address
  final BluetoothDevice _printerDevice =
      BluetoothDevice.fromId('C0:29:F6:DC:EB:BE');

  bool _isConnecting = false;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rongta Wi-Fi Setter',
          style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDeviceCard(),
              const SizedBox(height: 20),
              _buildWifiCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard() {
    // Display hardcoded printer information instead of scanning
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Target Printer',
              style: GoogleFonts.lato(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.indigo),
              title: const Text('Rongta Printer'),
              subtitle: Text(_printerDevice.remoteId.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Wi-Fi Credentials',
              style: GoogleFonts.lato(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(
                labelText: 'SSID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.wifi),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _isSending
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _sendWifiCredentials,
                    icon: const Icon(Icons.send),
                    label: const Text('Send to Printer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendWifiCredentials() async {
    final ssid = _ssidController.text;
    final password = _passwordController.text;

    if (ssid.isEmpty || password.isEmpty) {
      _showErrorDialog('SSID and password cannot be empty.');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      setState(() {
        _isConnecting = true;
      });
      await _bluetoothService.connect(_printerDevice);
      setState(() {
        _isConnecting = false;
      });

      // Use the correct UUIDs we discovered
      const serviceUuid = "0000ff00-0000-1000-8000-00805f9b34fb";
      const characteristicUuid = "0000ff02-0000-1000-8000-00805f9b34fb";

      final command = CommandBuilder.buildWifiCommand(ssid, password);
      await _bluetoothService.sendData(
          _printerDevice, serviceUuid, characteristicUuid, command);

      await _bluetoothService.disconnect(_printerDevice);

      _showSuccessDialog('Wi-Fi credentials sent successfully!');
    } catch (e) {
      _showErrorDialog('Error sending credentials: $e');
    } finally {
      setState(() {
        _isSending = false;
        _isConnecting = false;
      });
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
