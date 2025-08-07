// lib/services/hardware/hardware_detection_service.dart
// Service untuk mendeteksi dan mengelola perangkat hardware POS

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

enum HardwareType {
  thermalPrinter,
  barcodeScanner,
  cashDrawer,
  customerDisplay,
  scale,
  edc,
}

enum ConnectionType {
  usb,
  bluetooth,
  wifi,
  ethernet,
  serial,
}

class HardwareDevice {
  final String id;
  final String name;
  final String manufacturer;
  final HardwareType type;
  final ConnectionType connectionType;
  final String address; // MAC, IP, atau USB address
  final bool isConnected;
  final Map<String, dynamic> capabilities;

  HardwareDevice({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.type,
    required this.connectionType,
    required this.address,
    this.isConnected = false,
    this.capabilities = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'manufacturer': manufacturer,
        'type': type.toString(),
        'connectionType': connectionType.toString(),
        'address': address,
        'isConnected': isConnected,
        'capabilities': capabilities,
      };

  factory HardwareDevice.fromJson(Map<String, dynamic> json) => HardwareDevice(
        id: json['id'],
        name: json['name'],
        manufacturer: json['manufacturer'],
        type: HardwareType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => HardwareType.thermalPrinter,
        ),
        connectionType: ConnectionType.values.firstWhere(
          (e) => e.toString() == json['connectionType'],
          orElse: () => ConnectionType.usb,
        ),
        address: json['address'],
        isConnected: json['isConnected'] ?? false,
        capabilities: json['capabilities'] ?? {},
      );
}

class HardwareDetectionService {
  static final HardwareDetectionService _instance =
      HardwareDetectionService._internal();
  factory HardwareDetectionService() => _instance;
  HardwareDetectionService._internal();

  final StreamController<List<HardwareDevice>> _devicesController =
      StreamController<List<HardwareDevice>>.broadcast();

  Stream<List<HardwareDevice>> get devicesStream => _devicesController.stream;

  final List<HardwareDevice> _discoveredDevices = [];
  bool _isScanning = false;

  /// Initialize hardware detection service
  Future<void> initialize() async {
    try {
      await _requestPermissions();
      await _initializePlatformSpecific();
      print('✅ Hardware Detection Service initialized');
    } catch (e) {
      print('❌ Error initializing Hardware Detection Service: $e');
    }
  }

  /// Request necessary permissions for hardware access
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();
    }
  }

  /// Initialize platform-specific services
  Future<void> _initializePlatformSpecific() async {
    if (!kIsWeb) {
      // Initialize Bluetooth using flutter_blue_plus
      try {
        final adapterState = await FlutterBluePlus.adapterState.first;
        if (adapterState != BluetoothAdapterState.on) {
          print('⚠️ Bluetooth is not enabled');
        }
      } catch (e) {
        print('⚠️ Bluetooth initialization failed: $e');
      }
    }
  }

  /// Scan for all available hardware devices
  Future<void> scanForDevices() async {
    if (_isScanning) return;

    _isScanning = true;
    _discoveredDevices.clear();

    try {
      print('🔍 Starting hardware scan...');

      // Run scans
      await Future.wait([
        _scanBluetoothDevices(),
        _scanNetworkDevices(),
      ]);

      _devicesController.add(List.from(_discoveredDevices));
      print(
          '✅ Hardware scan completed. Found ${_discoveredDevices.length} devices');
    } catch (e) {
      print('❌ Error during hardware scan: $e');
    } finally {
      _isScanning = false;
    }
  }

  /// Scan for USB connected devices - Simplified for compatibility
  Future<void> _scanUSBDevices() async {
    if (kIsWeb) return;

    try {
      // USB device scanning would require additional setup
      // For now, we'll focus on Bluetooth and Network devices
      print('📱 USB scanning requires additional platform-specific setup');
    } catch (e) {
      print('❌ USB scan failed: $e');
    }
  }

  /// Scan for Bluetooth devices
  Future<void> _scanBluetoothDevices() async {
    if (kIsWeb) return;

    try {
      print(
          '⚠️ Bluetooth scanning using flutter_blue_plus requires updated implementation');
      print('💡 For now, focusing on Network and USB HID devices');

      // This would be the flutter_blue_plus implementation:
      // await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
      // FlutterBluePlus.scanResults.listen((results) {
      //   for (ScanResult r in results) {
      //     final hardwareDevice = _identifyBluetoothDevice(r.device);
      //     if (hardwareDevice != null) {
      //       _discoveredDevices.add(hardwareDevice);
      //     }
      //   }
      // });

      print('📶 Bluetooth scan completed (placeholder)');
    } catch (e) {
      print('❌ Bluetooth scan failed: $e');
    }
  }

  /// Scan for network printers and devices - Simplified
  Future<void> _scanNetworkDevices() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();

      if (wifiIP != null) {
        // Add some common network printer IPs as examples
        // In a real implementation, this would scan the network
        final commonPrinterIPs = [
          '192.168.1.100',
          '192.168.1.101',
          '192.168.1.102',
        ];

        for (final ip in commonPrinterIPs) {
          // Basic network device placeholder
          final device = HardwareDevice(
            id: 'network_$ip',
            name: 'Network Printer ($ip)',
            manufacturer: 'Unknown',
            type: HardwareType.thermalPrinter,
            connectionType: ConnectionType.wifi,
            address: ip,
            capabilities: {'port': 9100},
          );
          // Note: In production, you'd actually test connectivity
          // _discoveredDevices.add(device);
        }
      }

      print('🌐 Network scan completed');
    } catch (e) {
      print('❌ Network scan failed: $e');
    }
  }

  /// Identify USB device type based on vendor/product ID
  /// Identify USB device (placeholder - USB support simplified)
  HardwareDevice? _identifyUSBDevice(Map<String, dynamic> deviceInfo) {
    // Simplified USB device identification
    // In a real implementation, this would use platform channels
    // to identify USB devices by vendor/product IDs

    final name = deviceInfo['name'] ?? 'Unknown USB Device';
    final manufacturer = deviceInfo['manufacturer'] ?? 'Unknown';
    final address = deviceInfo['address'] ?? 'unknown';

    // Basic USB device placeholder
    return HardwareDevice(
      id: 'usb_$address',
      name: name,
      manufacturer: manufacturer,
      type: HardwareType.thermalPrinter, // Default assumption
      connectionType: ConnectionType.usb,
      address: address,
      capabilities: deviceInfo,
    );
  }

  /// Identify Bluetooth device type based on name and services
  HardwareDevice? _identifyBluetoothDevice(BluetoothDevice device) {
    final name = device.platformName.toLowerCase();
    final address = device.remoteId.toString();

    // Known printer patterns
    if (name.contains('printer') ||
        name.contains('pos') ||
        name.contains('thermal') ||
        name.contains('epson') ||
        name.contains('star') ||
        name.contains('citizen') ||
        name.contains('bixolon') ||
        name.contains('sunmi')) {
      return HardwareDevice(
        id: 'bt_printer_$address',
        name: device.platformName.isNotEmpty
            ? device.platformName
            : 'Bluetooth Printer',
        manufacturer: _extractManufacturer(name),
        type: HardwareType.thermalPrinter,
        connectionType: ConnectionType.bluetooth,
        address: address,
        capabilities: {
          'rssi':
              0, // This would need to be obtained differently in flutter_blue_plus
        },
      );
    }

    // Known scanner patterns
    if (name.contains('scanner') ||
        name.contains('barcode') ||
        name.contains('zebra') ||
        name.contains('honeywell') ||
        name.contains('datalogic')) {
      return HardwareDevice(
        id: 'bt_scanner_$address',
        name: device.platformName.isNotEmpty
            ? device.platformName
            : 'Bluetooth Scanner',
        manufacturer: _extractManufacturer(name),
        type: HardwareType.barcodeScanner,
        connectionType: ConnectionType.bluetooth,
        address: address,
        capabilities: {},
      );
    }

    return null;
  }

  /// Check if vendor ID belongs to known printer manufacturers
  bool _isPrinterVendor(int? vid) {
    if (vid == null) return false;

    // Known printer vendor IDs
    const printerVendors = [
      0x04b8, // Epson
      0x0519, // Star Micronics
      0x0483, // Citizen
      0x0525, // Bixolon
      0x1fc9, // Sunmi
      0x0fe6, // ICS Advent (Kontron)
      0x20d1, // XPRINTER
    ];

    return printerVendors.contains(vid);
  }

  /// Check if vendor ID belongs to known scanner manufacturers
  bool _isScannerVendor(int? vid) {
    if (vid == null) return false;

    // Known scanner vendor IDs
    const scannerVendors = [
      0x0a5c, // Zebra
      0x0c2e, // Honeywell
      0x05f9, // Datalogic
      0x1659, // Prolific
    ];

    return scannerVendors.contains(vid);
  }

  /// Extract manufacturer name from device name
  String _extractManufacturer(String deviceName) {
    final name = deviceName.toLowerCase();

    if (name.contains('epson')) return 'Epson';
    if (name.contains('star')) return 'Star Micronics';
    if (name.contains('citizen')) return 'Citizen';
    if (name.contains('bixolon')) return 'Bixolon';
    if (name.contains('sunmi')) return 'Sunmi';
    if (name.contains('zebra')) return 'Zebra';
    if (name.contains('honeywell')) return 'Honeywell';
    if (name.contains('datalogic')) return 'Datalogic';

    return 'Unknown';
  }

  /// Get list of discovered devices by type
  List<HardwareDevice> getDevicesByType(HardwareType type) {
    return _discoveredDevices.where((d) => d.type == type).toList();
  }

  /// Get device by ID
  HardwareDevice? getDeviceById(String id) {
    try {
      return _discoveredDevices.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Stop scanning and cleanup
  void dispose() {
    _devicesController.close();
  }
}
