
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
  BluetoothDevice? _selectedDevice;
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Bluetooth Device',
              style: GoogleFonts.lato(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_selectedDevice != null)
              ListTile(
                leading: const Icon(Icons.print, color: Colors.indigo),
                title: Text(_selectedDevice!.name.isNotEmpty
                    ? _selectedDevice!.name
                    : 'Unknown Device'),
                subtitle: Text(_selectedDevice!.remoteId.toString()),
              ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                _bluetoothService.startScan();
                _showDeviceSelectionDialog();
              },
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Scan for Printers'),
              style: ElevatedButton.styleFrom(
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

  void _showDeviceSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select a Printer'),
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
                      leading: const Icon(Icons.bluetooth, color: Colors.blue),
                      title: Text(device.name.isNotEmpty
                          ? device.name
                          : 'Unknown Device'),
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
      _showErrorDialog('No printer selected.');
      return;
    }

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
      await _bluetoothService.connect(_selectedDevice!);
      setState(() {
        _isConnecting = false;
      });

      // These UUIDs are placeholders and need to be found from the sniffing log.
      const serviceUuid = '00001800-0000-1000-8000-00805f9b34fb';
      const characteristicUuid = '00002a00-0000-1000-8000-00805f9b34fb';

      final command = CommandBuilder.buildWifiCommand(ssid, password);
      await _bluetoothService.sendData(
          _selectedDevice!, serviceUuid, characteristicUuid, command);

      await _bluetoothService.disconnect(_selectedDevice!);

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
