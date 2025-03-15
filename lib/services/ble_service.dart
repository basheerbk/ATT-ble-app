import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/material.dart';

class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  final String SERVICE_UUID = "12345678-1234-5678-1234-56789abcdef0";
  final String CHARACTERISTIC_UUID = "abcd1234-5678-1234-5678-abcdef123456";
  final String RENAME_CHARACTERISTIC_UUID =
      "abcd1234-5678-1234-5678-abcdef123457";

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  BluetoothDevice? _connectedDevice;
  bool _isConnected = false;
  BluetoothCharacteristic? _characteristic;
  bool _isTransmitting = false;

  // Getters
  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _isConnected;
  BluetoothCharacteristic? get characteristic => _characteristic;
  bool get isTransmitting => _isTransmitting;

  String _normalizeUUID(String uuid) {
    return uuid.replaceAll('-', '').toLowerCase();
  }

  Future<void> startScan(BuildContext context) async {
    if (_isScanning) return;

    _scanResults = [];
    _isScanning = true;

    try {
      if (!await FlutterBluePlus.isOn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable Bluetooth'),
            backgroundColor: Colors.orange,
          ),
        );
        _isScanning = false;
        return;
      }

      // Set a shorter scan timeout for faster updates
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));

      // Listen to scan results and update immediately
      FlutterBluePlus.scanResults.listen((results) {
        var filteredResults = results
            .where((result) =>
                result.device.name.isNotEmpty &&
                result.device.name.toUpperCase().startsWith('ESP'))
            .toList();

        // Update scan results only if there are changes
        if (filteredResults.length != _scanResults.length ||
            !_scanResults.every((existingResult) => filteredResults.any(
                (newResult) =>
                    newResult.device.id == existingResult.device.id))) {
          _scanResults = filteredResults;
        }
      }, onDone: () {
        _isScanning = false;
      });

      // Monitor scanning state
      FlutterBluePlus.isScanning.listen((isScanning) {
        _isScanning = isScanning;
        if (!isScanning && _scanResults.isEmpty) {
          // Restart scan if no devices found
          startScan(context);
        }
      }, onError: (e) {
        print('Scanning state error: $e');
        _isScanning = false;
      });
    } catch (e) {
      print('Scan error: $e');
      _isScanning = false;
    }
  }

  Future<void> connectToDevice(
      BluetoothDevice device, BuildContext context) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      _isConnected = true;

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        if (_normalizeUUID(service.uuid.toString()) ==
            _normalizeUUID(SERVICE_UUID)) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (_normalizeUUID(characteristic.uuid.toString()) ==
                _normalizeUUID(CHARACTERISTIC_UUID)) {
              _characteristic = characteristic;
              await _characteristic!.setNotifyValue(true);
              _characteristic!.value.listen((value) {
                String message = String.fromCharCodes(value);
                if (message == 'req_data' && !_isTransmitting) {
                  sendSyncData();
                }
              });
              return;
            }
          }
        }
      }
      throw Exception('Service or characteristic not found');
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
      _connectedDevice = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> disconnectDevice(BuildContext context) async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _characteristic = null;
        _isConnected = false;
      }
    } catch (e) {
      print('Disconnect error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> renameDevice(String newName, BuildContext context) async {
    if (_connectedDevice == null) return;

    try {
      final fullName = 'ESP_$newName';

      final services = await _connectedDevice!.discoverServices();
      for (BluetoothService service in services) {
        if (_normalizeUUID(service.uuid.toString()) ==
            _normalizeUUID(SERVICE_UUID)) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (_normalizeUUID(characteristic.uuid.toString()) ==
                _normalizeUUID(RENAME_CHARACTERISTIC_UUID)) {
              await characteristic.write(fullName.codeUnits);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Device renamed to: $fullName'),
                  backgroundColor: Colors.green,
                ),
              );
              return;
            }
          }
        }
      }
      throw Exception('Rename characteristic not found');
    } catch (e) {
      print('Rename error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rename device: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> sendSyncData() async {
    if (_characteristic == null || _isTransmitting) return;

    final data = {
      'sliders': [
        {
          'id': 1,
          'image_url': 'https://your-cdn.com/images/slider1.jpg',
          'alt_text': 'Promotional Banner 1'
        },
        {
          'id': 2,
          'image_url': 'https://your-cdn.com/images/slider2.jpg',
          'alt_text': 'Promotional Banner 2'
        },
        {
          'id': 3,
          'image_url': 'https://your-cdn.com/images/slider3.jpg',
          'alt_text': 'Promotional Banner 3'
        }
      ],
      'cards': [
        {
          'id': 101,
          'title': 'Fast & Secure',
          'description':
              'Experience blazing fast speed with top-notch security.',
          'image_url': 'https://your-cdn.com/images/card1.jpg'
        },
        {
          'id': 102,
          'title': 'Affordable Pricing',
          'description':
              'Get the best value is 123 for your money with our budget-friendly plans.',
          'image_url': 'https://your-cdn.com/images/card2.jpg'
        },
        {
          'id': 103,
          'title': '24/7 Support',
          'description':
              'Our dedicated team is always available to assist you anytime.',
          'image_url': 'https://your-cdn.com/images/card3.jpg'
        }
      ]
    };
    await sendResponseInChunks(jsonEncode(data));
  }

  Future<void> syncWithESP(BuildContext context) async {
    if (_characteristic == null) return;

    try {
      print('Sending SYNC command...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Syncing with device...'),
          backgroundColor: Colors.blue,
        ),
      );
      await _characteristic!.write('SYNC'.codeUnits);
      print('SYNC command sent');
    } catch (e) {
      print('Sync error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> sendResponseInChunks(String data) async {
    if (_characteristic == null || _isTransmitting) return;

    const int CHUNK_SIZE = 20;
    const Duration CHUNK_DELAY = Duration(milliseconds: 50);

    try {
      _isTransmitting = true;
      final markedData = "strS${data}strE";
      print('Total data length: ${markedData.length}');

      for (var i = 0; i < markedData.length; i += CHUNK_SIZE) {
        if (!_isConnected) {
          print('Connection lost while sending chunks');
          _isTransmitting = false;
          return;
        }

        var end = (i + CHUNK_SIZE < markedData.length)
            ? i + CHUNK_SIZE
            : markedData.length;
        String chunk = markedData.substring(i, end);

        print(
            'Sending chunk ${(i ~/ CHUNK_SIZE) + 1}/${(markedData.length / CHUNK_SIZE).ceil()}');
        await _characteristic!.write(chunk.codeUnits);
        await Future.delayed(CHUNK_DELAY);
      }

      print('All chunks sent');
      _isTransmitting = false;
    } catch (e) {
      _isTransmitting = false;
      print('Error sending chunks: $e');
    }
  }
}
