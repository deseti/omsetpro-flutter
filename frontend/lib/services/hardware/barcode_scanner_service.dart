// lib/services/hardware/barcode_scanner_service.dart
// Real barcode scanner service untuk scanner eksternal USB/Bluetooth

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'hardware_detection_service.dart';

enum ScannerType {
  laser,
  imager,
  ccd,
  camera,
}

enum ScannerStatus {
  disconnected,
  connecting,
  connected,
  scanning,
  error,
}

class BarcodeResult {
  final String data;
  final String symbology;
  final DateTime timestamp;
  final String? rawData;

  BarcodeResult({
    required this.data,
    required this.symbology,
    required this.timestamp,
    this.rawData,
  });

  Map<String, dynamic> toJson() => {
        'data': data,
        'symbology': symbology,
        'timestamp': timestamp.toIso8601String(),
        'rawData': rawData,
      };
}

class BarcodeScannerService {
  static final BarcodeScannerService _instance =
      BarcodeScannerService._internal();
  factory BarcodeScannerService() => _instance;
  BarcodeScannerService._internal();

  // Scanner connections
  // Note: USB support removed for now, will use keyboard event listeners for USB HID scanners
  BluetoothDevice? _bluetoothDevice;
  BluetoothCharacteristic? _bluetoothCharacteristic;

  // Current state
  HardwareDevice? _connectedDevice;
  ScannerStatus _status = ScannerStatus.disconnected;
  bool _isListening = false;

  // Stream controllers
  final StreamController<BarcodeResult> _barcodeController =
      StreamController<BarcodeResult>.broadcast();
  final StreamController<ScannerStatus> _statusController =
      StreamController<ScannerStatus>.broadcast();

  Stream<BarcodeResult> get barcodeStream => _barcodeController.stream;
  Stream<ScannerStatus> get statusStream => _statusController.stream;
  ScannerStatus get currentStatus => _status;
  HardwareDevice? get connectedDevice => _connectedDevice;

  // Keyboard listener for USB HID scanners
  String _barcodeBuffer = '';
  Timer? _barcodeTimer;

  /// Initialize the barcode scanner service
  Future<void> initialize() async {
    try {
      // Initialize keyboard listener for USB HID scanners
      if (!kIsWeb) {
        _initializeKeyboardListener();
      }
      print('✅ Barcode Scanner Service initialized');
    } catch (e) {
      print('❌ Error initializing Barcode Scanner Service: $e');
    }
  }

  /// Initialize keyboard listener for USB HID barcode scanners
  void _initializeKeyboardListener() {
    try {
      // Initialize raw keyboard listener for USB HID scanners
      // This will be handled at the widget level for better integration
      print('✅ USB HID scanner support initialized');
    } catch (e) {
      print('⚠️ Keyboard listener initialization failed: $e');
    }
  }

  /// Handle raw key event from USB HID scanner
  void handleRawKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent && _connectedDevice != null && _isListening) {
      final key = event.logicalKey;

      // Handle Enter key (barcode scan complete)
      if (key == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.isNotEmpty) {
          final result = BarcodeResult(
            data: _barcodeBuffer,
            symbology: 'Unknown', // HID doesn't provide symbology
            timestamp: DateTime.now(),
          );
          _barcodeController.add(result);
          print('📱 HID Scanner: $_barcodeBuffer');
          _barcodeBuffer = '';
        }
        return;
      }

      // Handle regular characters
      final character = event.character;
      if (character != null && character.isNotEmpty) {
        _barcodeBuffer += character;

        // Reset timer for barcode completion
        _barcodeTimer?.cancel();
        _barcodeTimer = Timer(const Duration(milliseconds: 100), () {
          // If no more characters received, assume barcode is complete
          if (_barcodeBuffer.isNotEmpty) {
            final result = BarcodeResult(
              data: _barcodeBuffer,
              symbology: 'Unknown',
              timestamp: DateTime.now(),
            );
            _barcodeController.add(result);
            print('📱 HID Scanner (timeout): $_barcodeBuffer');
            _barcodeBuffer = '';
          }
        });
      }
    }
  }

  /// Connect to a specific scanner device
  Future<bool> connect(HardwareDevice device) async {
    if (device.type != HardwareType.barcodeScanner) {
      print('❌ Device is not a barcode scanner');
      return false;
    }

    _updateStatus(ScannerStatus.connecting);

    try {
      bool connected = false;

      switch (device.connectionType) {
        case ConnectionType.bluetooth:
          connected = await _connectBluetooth(device);
          break;
        case ConnectionType.usb:
          connected = await _connectUSB(device);
          break;
        default:
          print('❌ Unsupported connection type: ${device.connectionType}');
          connected = false;
      }

      if (connected) {
        _connectedDevice = device;
        _updateStatus(ScannerStatus.connected);
        _isListening = true;
        print('✅ Connected to scanner: ${device.name}');

        // Start listening for scans
        await _startListening();
      } else {
        _updateStatus(ScannerStatus.error);
        print('❌ Failed to connect to scanner: ${device.name}');
      }

      return connected;
    } catch (e) {
      _updateStatus(ScannerStatus.error);
      print('❌ Error connecting to scanner: $e');
      return false;
    }
  }

  /// Connect to Bluetooth scanner
  Future<bool> _connectBluetooth(HardwareDevice device) async {
    try {
      print(
          '⚠️ Bluetooth scanner connection using flutter_blue_plus requires updated implementation');
      print(
          '💡 Please use USB HID scanners for now or implement full flutter_blue_plus integration');
      return false;
    } catch (e) {
      print('❌ Bluetooth scanner connection failed: $e');
      return false;
    }
  }

  /// Connect to USB scanner (simplified - using keyboard events for USB HID scanners)
  Future<bool> _connectUSB(HardwareDevice device) async {
    try {
      // USB HID scanners typically work as keyboard input devices
      // They don't require special drivers and send keystrokes
      print('✅ USB HID scanner ready: ${device.name}');
      print('💡 USB scanners will work through keyboard event listeners');
      return true;
    } catch (e) {
      print('❌ USB scanner connection failed: $e');
      return false;
    }
  }

  /// Start listening for barcode scans
  Future<void> _startListening() async {
    if (_connectedDevice == null) return;

    _updateStatus(ScannerStatus.scanning);

    try {
      switch (_connectedDevice!.connectionType) {
        case ConnectionType.bluetooth:
          await _listenBluetooth();
          break;
        case ConnectionType.usb:
          await _listenUSB();
          break;
        default:
          break;
      }
    } catch (e) {
      print('❌ Error starting scanner listener: $e');
      _updateStatus(ScannerStatus.error);
    }
  }

  /// Listen for Bluetooth scanner data
  Future<void> _listenBluetooth() async {
    print(
        '⚠️ Bluetooth scanner listening using flutter_blue_plus requires updated implementation');
    print('� Please use USB HID scanners for now');
  }

  /// Listen for USB scanner data (simplified for USB HID)
  Future<void> _listenUSB() async {
    // USB HID scanners work as keyboard input devices
    // They send keystrokes that can be captured via keyboard event listeners
    // This is a placeholder for future implementation using platform channels
    print('� USB HID scanner listening via keyboard events');

    // For now, we'll just mark as ready
    // In a real implementation, this would set up keyboard event listeners
    // to capture barcode scans from USB HID devices
  }

  /// Send command to scanner (for advanced scanners)
  Future<bool> sendCommand(String command) async {
    if (_connectedDevice == null) return false;

    try {
      // Convert command to bytes for transmission
      command.codeUnits;

      switch (_connectedDevice!.connectionType) {
        case ConnectionType.bluetooth:
          if (_bluetoothCharacteristic != null) {
            final commandBytes = Uint8List.fromList(command.codeUnits);
            await _bluetoothCharacteristic!.write(commandBytes);
            return true;
          }
          break;
        case ConnectionType.usb:
          // USB HID scanners don't typically accept commands
          // They work as keyboard input devices
          print(
              '💡 USB HID scanners work as keyboard input - no command sending needed');
          return true;
        default:
          break;
      }

      return false;
    } catch (e) {
      print('❌ Error sending scanner command: $e');
      return false;
    }
  }

  /// Trigger scan (for supported scanners)
  Future<bool> triggerScan() async {
    // Send trigger command - this varies by manufacturer
    final commands = [
      '\x16T\r\n', // Honeywell
      '\x1B\x31', // Zebra
      'TRIGGER_SCAN\r\n', // Generic
    ];

    for (final command in commands) {
      if (await sendCommand(command)) {
        return true;
      }
    }

    return false;
  }

  /// Configure scanner settings
  Future<bool> configureScannerSettings({
    bool? enableBeep,
    bool? enableVibration,
    int? timeout,
    List<String>? enabledSymbologies,
  }) async {
    if (_connectedDevice == null) return false;

    try {
      // This would send configuration commands specific to the scanner model
      // Each manufacturer has different command sets

      if (enableBeep != null) {
        final command = enableBeep ? 'BEEP_ON\r\n' : 'BEEP_OFF\r\n';
        await sendCommand(command);
      }

      if (timeout != null) {
        final command = 'TIMEOUT_$timeout\r\n';
        await sendCommand(command);
      }

      return true;
    } catch (e) {
      print('❌ Error configuring scanner: $e');
      return false;
    }
  }

  /// Test scanner functionality
  Future<bool> testScanner() async {
    if (_connectedDevice == null) return false;

    try {
      // Send test command or trigger scan
      return await triggerScan();
    } catch (e) {
      print('❌ Scanner test failed: $e');
      return false;
    }
  }

  /// Stop listening for scans
  void stopListening() {
    _isListening = false;
    if (_status == ScannerStatus.scanning) {
      _updateStatus(ScannerStatus.connected);
    }
  }

  /// Resume listening for scans
  void resumeListening() {
    if (_connectedDevice != null && !_isListening) {
      _isListening = true;
      _startListening();
    }
  }

  /// Disconnect from current scanner
  Future<void> disconnect() async {
    try {
      _isListening = false;

      if (_bluetoothDevice != null) {
        await _bluetoothDevice!.disconnect();
        _bluetoothDevice = null;
        _bluetoothCharacteristic = null;
      }

      // USB HID scanners don't need explicit disconnection
      // They work as keyboard input devices

      _connectedDevice = null;
      _updateStatus(ScannerStatus.disconnected);
      print('✅ Scanner disconnected');
    } catch (e) {
      print('❌ Error disconnecting scanner: $e');
    }
  }

  /// Update scanner status
  void _updateStatus(ScannerStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Get scanner status text
  String getStatusText() {
    switch (_status) {
      case ScannerStatus.disconnected:
        return 'Disconnected';
      case ScannerStatus.connecting:
        return 'Connecting...';
      case ScannerStatus.connected:
        return 'Connected';
      case ScannerStatus.scanning:
        return 'Ready to Scan';
      case ScannerStatus.error:
        return 'Error';
    }
  }

  /// Cleanup resources
  void dispose() {
    disconnect();
    _barcodeTimer?.cancel();
    _barcodeController.close();
    _statusController.close();
  }
}
