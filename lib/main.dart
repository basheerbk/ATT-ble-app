import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'services/ble_service.dart';
import 'widgets/device_list_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  await Permission.bluetoothScan.request();
  await Permission.bluetoothConnect.request();
  await Permission.location.request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 ATT APP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'ESP32 ATT app'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final BLEService _bleService = BLEService();
  bool get _isConnected => _bleService.isConnected;
  bool get _isScanning => _bleService.isScanning;

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _startScan() async {
    await _bleService.startScan(context);
    setState(() {});
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _bleService.connectToDevice(device, context);
    setState(() {});
  }

  Future<void> _disconnectDevice() async {
    await _bleService.disconnectDevice(context);
    setState(() {});
  }

  Future<void> _renameDevice(String newName) async {
    await _bleService.renameDevice(newName, context);
    setState(() {});
  }

  Future<void> _showRenameDialog(BuildContext context) async {
    final TextEditingController _controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Device'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter new name (e.g., Mango)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = _controller.text.trim();
                if (newName.isNotEmpty) {
                  await _renameDevice(newName);
                  Navigator.pop(context);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendSyncData() async {
    await _bleService.sendSyncData();
    setState(() {});
  }

  Future<void> _syncWithESP() async {
    await _bleService.syncWithESP(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Scan Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _isConnected || _isScanning ? null : _startScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Device List
              DeviceListWidget(
                scanResults: _bleService.scanResults,
                connectedDevice: _bleService.connectedDevice,
                onConnect: _connectToDevice,
                onDisconnect: _disconnectDevice,
              ),
            ],
          ),

          // Centered Sync Button
          if (_bleService.isConnected)
            Center(
              child: ElevatedButton.icon(
                onPressed: _syncWithESP,
                icon: const Icon(Icons.sync),
                label: const Text('Sync with Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          // Rename Button
          if (_isConnected)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _showRenameDialog(context),
                child: const Icon(Icons.edit),
              ),
            ),
        ],
      ),
    );
  }
}
