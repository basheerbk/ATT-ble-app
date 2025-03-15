import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';

class DeviceListWidget extends StatelessWidget {
  final List<ScanResult> scanResults;
  final BluetoothDevice? connectedDevice;
  final Function(BluetoothDevice) onConnect;
  final VoidCallback onDisconnect;

  const DeviceListWidget({
    super.key,
    required this.scanResults,
    required this.connectedDevice,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: scanResults.isEmpty
          ? Center(
              child: Text(
                BLEService().isScanning
                    ? 'Searching for devices...'
                    : 'No devices found. Tap Scan to start searching.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: scanResults.length,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemBuilder: (context, index) {
                final device = scanResults[index].device;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      device.name.isEmpty ? 'Unknown Device' : device.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(device.id.id),
                    trailing: connectedDevice?.id == device.id
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Connected',
                                style: TextStyle(color: Colors.green),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: onDisconnect,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Disconnect'),
                              ),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: () => onConnect(device),
                            child: const Text('Connect'),
                          ),
                  ),
                );
              },
            ),
    );
  }
}
