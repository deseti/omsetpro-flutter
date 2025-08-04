// lib/services/hardware/hardware_manager_service.dart
// Central hardware manager untuk semua perangkat POS

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hardware_detection_service.dart';
import 'thermal_printer_service.dart';
import 'barcode_scanner_service.dart';

class HardwareManagerService {
  static final HardwareManagerService _instance = HardwareManagerService._internal();
  factory HardwareManagerService() => _instance;
  HardwareManagerService._internal() {
    // Initialize services immediately but safely
    _detectionService = HardwareDetectionService();
    _printerService = ThermalPrinterService();
    _scannerService = BarcodeScannerService();
  }

  // Services - initialized in constructor
  late final HardwareDetectionService _detectionService;
  late final ThermalPrinterService _printerService;
  late final BarcodeScannerService _scannerService;

  // State
  bool _isInitialized = false;
  List<HardwareDevice> _availableDevices = [];
  
  // Stream controllers
  final StreamController<List<HardwareDevice>> _devicesController = 
      StreamController<List<HardwareDevice>>.broadcast();
  final StreamController<String> _notificationController = 
      StreamController<String>.broadcast();
  
  Stream<List<HardwareDevice>> get devicesStream => _devicesController.stream;
  Stream<String> get notificationStream => _notificationController.stream;
  
  // Getters for services
  HardwareDetectionService get detectionService => _detectionService;
  ThermalPrinterService get printerService => _printerService;
  BarcodeScannerService get scannerService => _scannerService;
  
  List<HardwareDevice> get availableDevices => List.from(_availableDevices);
  bool get isInitialized => _isInitialized;

  /// Initialize all hardware services
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔧 Initializing Hardware Manager...');
      
      // Services are already created in constructor, now initialize them
      await Future.wait([
        _detectionService.initialize(),
        _printerService.initialize(),
        _scannerService.initialize(),
      ]);
      
      // Listen to device discovery
      _detectionService.devicesStream.listen((devices) {
        _availableDevices = devices;
        _devicesController.add(devices);
        _notificationController.add('Found ${devices.length} hardware devices');
      });
      
      // Listen to printer status
      _printerService.statusStream.listen((status) {
        _notificationController.add('Printer: ${_printerService.getStatusText()}');
      });
      
      // Listen to scanner status
      _scannerService.statusStream.listen((status) {
        _notificationController.add('Scanner: ${_scannerService.getStatusText()}');
      });
      
      // Listen to barcode scans
      _scannerService.barcodeStream.listen((barcode) {
        _notificationController.add('Scanned: ${barcode.data}');
      });
      
      // Load saved device configurations
      await _loadSavedConfigurations();
      
      // Auto-discover devices
      await scanForDevices();
      
      _isInitialized = true;
      print('✅ Hardware Manager initialized successfully');
      
    } catch (e) {
      print('❌ Error initializing Hardware Manager: $e');
      throw Exception('Failed to initialize hardware manager: $e');
    }
  }

  /// Scan for all available hardware devices
  Future<void> scanForDevices() async {
    try {
      _notificationController.add('Scanning for hardware devices...');
      await _detectionService.scanForDevices();
    } catch (e) {
      print('❌ Error scanning for devices: $e');
      _notificationController.add('Device scan failed: $e');
    }
  }

  /// Connect to a specific device
  Future<bool> connectDevice(String deviceId) async {
    try {
      final device = _detectionService.getDeviceById(deviceId);
      if (device == null) {
        _notificationController.add('Device not found: $deviceId');
        return false;
      }
      
      bool connected = false;
      
      switch (device.type) {
        case HardwareType.thermalPrinter:
          connected = await _printerService.connect(device);
          if (connected) {
            await _saveDeviceConfiguration(device, 'default_printer');
          }
          break;
        case HardwareType.barcodeScanner:
          connected = await _scannerService.connect(device);
          if (connected) {
            await _saveDeviceConfiguration(device, 'default_scanner');
          }
          break;
        case HardwareType.cashDrawer:
          // Cash drawer is usually connected via printer
          _notificationController.add('Cash drawer controlled via printer');
          connected = true;
          break;
        default:
          _notificationController.add('Unsupported device type: ${device.type}');
          connected = false;
      }
      
      if (connected) {
        _notificationController.add('Connected to ${device.name}');
      } else {
        _notificationController.add('Failed to connect to ${device.name}');
      }
      
      return connected;
    } catch (e) {
      print('❌ Error connecting device: $e');
      _notificationController.add('Connection error: $e');
      return false;
    }
  }

  /// Disconnect a specific device
  Future<void> disconnectDevice(HardwareType deviceType) async {
    try {
      switch (deviceType) {
        case HardwareType.thermalPrinter:
          await _printerService.disconnect();
          break;
        case HardwareType.barcodeScanner:
          await _scannerService.disconnect();
          break;
        default:
          break;
      }
      
      _notificationController.add('Disconnected ${deviceType.toString()}');
    } catch (e) {
      print('❌ Error disconnecting device: $e');
      _notificationController.add('Disconnection error: $e');
    }
  }

  /// Auto-connect to saved default devices
  Future<void> autoConnectSavedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Auto-connect default printer
      final defaultPrinterId = prefs.getString('default_printer');
      if (defaultPrinterId != null) {
        final printer = _detectionService.getDeviceById(defaultPrinterId);
        if (printer != null) {
          await connectDevice(defaultPrinterId);
        }
      }
      
      // Auto-connect default scanner
      final defaultScannerId = prefs.getString('default_scanner');
      if (defaultScannerId != null) {
        final scanner = _detectionService.getDeviceById(defaultScannerId);
        if (scanner != null) {
          await connectDevice(defaultScannerId);
        }
      }
      
    } catch (e) {
      print('❌ Error auto-connecting devices: $e');
    }
  }

  /// Get devices by type
  List<HardwareDevice> getDevicesByType(HardwareType type) {
    return _availableDevices.where((d) => d.type == type).toList();
  }

  /// Get connected devices
  Map<HardwareType, HardwareDevice?> getConnectedDevices() {
    return {
      HardwareType.thermalPrinter: _printerService.connectedDevice,
      HardwareType.barcodeScanner: _scannerService.connectedDevice,
    };
  }

  /// Check if specific hardware type is connected
  bool isDeviceConnected(HardwareType type) {
    switch (type) {
      case HardwareType.thermalPrinter:
        return _printerService.currentStatus == PrinterStatus.connected ||
               _printerService.currentStatus == PrinterStatus.printing;
      case HardwareType.barcodeScanner:
        return _scannerService.currentStatus == ScannerStatus.connected ||
               _scannerService.currentStatus == ScannerStatus.scanning;
      case HardwareType.cashDrawer:
        // Cash drawer availability depends on printer
        return isDeviceConnected(HardwareType.thermalPrinter);
      default:
        return false;
    }
  }

  /// Print receipt using connected printer
  Future<PrintResult> printReceipt({
    required String receiptText,
    bool autoCut = true,
    bool openDrawer = false,
  }) async {
    if (!isDeviceConnected(HardwareType.thermalPrinter)) {
      return PrintResult(
        success: false,
        message: 'No printer connected',
      );
    }
    
    return await _printerService.printReceipt(
      receiptText: receiptText,
      autoCut: autoCut,
      openDrawer: openDrawer,
    );
  }

  /// Open cash drawer
  Future<PrintResult> openCashDrawer() async {
    if (!isDeviceConnected(HardwareType.thermalPrinter)) {
      return PrintResult(
        success: false,
        message: 'No printer connected for cash drawer',
      );
    }
    
    return await _printerService.openCashDrawer();
  }

  /// Test hardware functionality
  Future<Map<HardwareType, bool>> testAllHardware() async {
    final results = <HardwareType, bool>{};
    
    // Test printer
    if (isDeviceConnected(HardwareType.thermalPrinter)) {
      final printResult = await _printerService.printTestPage();
      results[HardwareType.thermalPrinter] = printResult.success;
    }
    
    // Test scanner
    if (isDeviceConnected(HardwareType.barcodeScanner)) {
      final scanResult = await _scannerService.testScanner();
      results[HardwareType.barcodeScanner] = scanResult;
    }
    
    // Test cash drawer
    if (isDeviceConnected(HardwareType.cashDrawer)) {
      final drawerResult = await openCashDrawer();
      results[HardwareType.cashDrawer] = drawerResult.success;
    }
    
    return results;
  }

  /// Get hardware status summary
  Map<String, dynamic> getHardwareStatus() {
    return {
      'printer': {
        'connected': isDeviceConnected(HardwareType.thermalPrinter),
        'status': _printerService.getStatusText(),
        'device': _printerService.connectedDevice?.toJson(),
      },
      'scanner': {
        'connected': isDeviceConnected(HardwareType.barcodeScanner),
        'status': _scannerService.getStatusText(),
        'device': _scannerService.connectedDevice?.toJson(),
      },
      'cashDrawer': {
        'available': isDeviceConnected(HardwareType.thermalPrinter),
      },
      'totalDevices': _availableDevices.length,
      'lastScan': DateTime.now().toIso8601String(),
    };
  }

  /// Save device configuration
  Future<void> _saveDeviceConfiguration(HardwareDevice device, String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, device.id);
      await prefs.setString('${key}_config', device.toJson().toString());
    } catch (e) {
      print('❌ Error saving device configuration: $e');
    }
  }

  /// Load saved device configurations
  Future<void> _loadSavedConfigurations() async {
    try {
      // This could load saved device preferences, settings, etc.
      print('📋 Loading saved hardware configurations...');
    } catch (e) {
      print('❌ Error loading configurations: $e');
    }
  }

  /// Export hardware configuration
  Map<String, dynamic> exportConfiguration() {
    return {
      'devices': _availableDevices.map((d) => d.toJson()).toList(),
      'connectedDevices': getConnectedDevices().map(
        (key, value) => MapEntry(key.toString(), value?.toJson()),
      ),
      'status': getHardwareStatus(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Cleanup and dispose all services
  void dispose() {
    _printerService.dispose();
    _scannerService.dispose();
    _detectionService.dispose();
    _devicesController.close();
    _notificationController.close();
  }
}
