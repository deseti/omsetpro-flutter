// lib/services/hardware/thermal_printer_service.dart
// Real thermal printer service dengan dukungan Bluetooth dan WiFi

import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'hardware_detection_service.dart';

enum PrinterStatus {
  disconnected,
  connecting,
  connected,
  printing,
  error,
  paperOut,
  coverOpen,
}

class PrintResult {
  final bool success;
  final String message;
  final PrinterStatus? status;

  PrintResult({
    required this.success,
    required this.message,
    this.status,
  });
}

class ThermalPrinterService {
  static final ThermalPrinterService _instance = ThermalPrinterService._internal();
  factory ThermalPrinterService() => _instance;
  ThermalPrinterService._internal();

  // Printer connections
  Socket? _networkSocket;
  BluetoothCharacteristic? _bluetoothCharacteristic;
  BluetoothDevice? _bluetoothDevice;
  
  // Current state
  HardwareDevice? _connectedDevice;
  PrinterStatus _status = PrinterStatus.disconnected;
  
  // Stream controllers
  final StreamController<PrinterStatus> _statusController = 
      StreamController<PrinterStatus>.broadcast();
  
  Stream<PrinterStatus> get statusStream => _statusController.stream;
  PrinterStatus get currentStatus => _status;
  HardwareDevice? get connectedDevice => _connectedDevice;

  /// Initialize the thermal printer service
  Future<void> initialize() async {
    try {
      print('✅ Thermal Printer Service initialized');
    } catch (e) {
      print('❌ Error initializing Thermal Printer Service: $e');
    }
  }

  /// Connect to a specific printer device
  Future<bool> connect(HardwareDevice device) async {
    if (device.type != HardwareType.thermalPrinter) {
      print('❌ Device is not a thermal printer');
      return false;
    }

    _updateStatus(PrinterStatus.connecting);
    
    try {
      bool connected = false;
      
      switch (device.connectionType) {
        case ConnectionType.bluetooth:
          connected = await _connectBluetooth(device);
          break;
        case ConnectionType.wifi:
        case ConnectionType.ethernet:
          connected = await _connectNetwork(device);
          break;
        default:
          print('❌ Unsupported connection type: ${device.connectionType}');
          connected = false;
      }
      
      if (connected) {
        _connectedDevice = device;
        _updateStatus(PrinterStatus.connected);
        print('✅ Connected to printer: ${device.name}');
        
        // Test printer status
        await _checkPrinterStatus();
      } else {
        _updateStatus(PrinterStatus.error);
        print('❌ Failed to connect to printer: ${device.name}');
      }
      
      return connected;
    } catch (e) {
      _updateStatus(PrinterStatus.error);
      print('❌ Error connecting to printer: $e');
      return false;
    }
  }

  /// Connect to Bluetooth printer
  Future<bool> _connectBluetooth(HardwareDevice device) async {
    try {
      // For flutter_blue_plus, we need to implement a different approach
      // This is a simplified implementation
      print('⚠️ Bluetooth printer connection using flutter_blue_plus requires updated implementation');
      print('💡 Please use Network/WiFi printers for now or implement full flutter_blue_plus integration');
      return false;
      
    } catch (e) {
      print('❌ Bluetooth connection failed: $e');
      return false;
    }
  }

  /// Connect to USB printer
  Future<bool> _connectUSB(HardwareDevice device) async {
    // USB support removed for compatibility
    print('⚠️ USB printer support requires additional setup');
    return false;
  }

  /// Connect to network printer
  Future<bool> _connectNetwork(HardwareDevice device) async {
    try {
      final ip = device.address;
      final port = device.capabilities['port'] as int? ?? 9100;
      
      _networkSocket = await Socket.connect(ip, port);
      
      if (_networkSocket != null) {
        print('✅ Network printer connected: $ip:$port');
        return true;
      } else {
        print('❌ Network connection failed');
        return false;
      }
    } catch (e) {
      print('❌ Network connection failed: $e');
      return false;
    }
  }

  /// Print receipt using ESC/POS commands
  Future<PrintResult> printReceipt({
    required String receiptText,
    bool autoCut = true,
    bool openDrawer = false,
  }) async {
    if (_connectedDevice == null) {
      return PrintResult(
        success: false,
        message: 'No printer connected',
        status: PrinterStatus.disconnected,
      );
    }

    _updateStatus(PrinterStatus.printing);
    
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      final List<int> bytes = [];

      // Generate ESC/POS commands for receipt
      bytes.addAll(generator.reset());
      bytes.addAll(generator.text(receiptText, styles: const PosStyles()));
      
      if (autoCut) {
        bytes.addAll(generator.cut());
      }
      
      if (openDrawer) {
        bytes.addAll(generator.drawer());
      }
      
      bytes.addAll(generator.feed(2));

      // Send to printer based on connection type
      bool success = false;
      switch (_connectedDevice!.connectionType) {
        case ConnectionType.bluetooth:
          success = await _printBluetooth(bytes);
          break;
        case ConnectionType.wifi:
        case ConnectionType.ethernet:
          success = await _printNetwork(bytes);
          break;
        default:
          success = false;
      }
      
      _updateStatus(success ? PrinterStatus.connected : PrinterStatus.error);
      
      return PrintResult(
        success: success,
        message: success ? 'Receipt printed successfully' : 'Print failed',
        status: _status,
      );
      
    } catch (e) {
      _updateStatus(PrinterStatus.error);
      return PrintResult(
        success: false,
        message: 'Print error: $e',
        status: PrinterStatus.error,
      );
    }
  }

  /// Print via Bluetooth
  Future<bool> _printBluetooth(List<int> bytes) async {
    try {
      print('⚠️ Bluetooth printing using flutter_blue_plus requires updated implementation');
      print('💡 Please use Network/WiFi printers for now');
      return false;
    } catch (e) {
      print('❌ Bluetooth print failed: $e');
      return false;
    }
  }

  /// Print via USB
  Future<bool> _printUSB(List<int> bytes) async {
    // USB support removed for compatibility
    print('⚠️ USB printing requires additional setup');
    return false;
  }

  /// Print via Network
  Future<bool> _printNetwork(List<int> bytes) async {
    try {
      if (_networkSocket == null) return false;
      
      _networkSocket!.add(bytes);
      await _networkSocket!.flush();
      
      return true;
    } catch (e) {
      print('❌ Network print failed: $e');
      return false;
    }
  }

  /// Open cash drawer
  Future<PrintResult> openCashDrawer() async {
    if (_connectedDevice == null) {
      return PrintResult(
        success: false,
        message: 'No printer connected',
      );
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      final bytes = generator.drawer();

      bool success = false;
      switch (_connectedDevice!.connectionType) {
        case ConnectionType.bluetooth:
          success = await _printBluetooth(bytes);
          break;
        case ConnectionType.wifi:
        case ConnectionType.ethernet:
          success = await _printNetwork(bytes);
          break;
        default:
          success = false;
      }

      return PrintResult(
        success: success,
        message: success ? 'Cash drawer opened' : 'Failed to open cash drawer',
      );
    } catch (e) {
      return PrintResult(
        success: false,
        message: 'Error opening cash drawer: $e',
      );
    }
  }

  /// Check printer status
  Future<void> _checkPrinterStatus() async {
    try {
      // This would normally query the printer for status
      // For now, we'll assume it's working if connected
      if (_connectedDevice != null) {
        _updateStatus(PrinterStatus.connected);
      }
    } catch (e) {
      _updateStatus(PrinterStatus.error);
    }
  }

  /// Print test page
  Future<PrintResult> printTestPage() async {
    final testReceipt = '''
================================
        OMSETPRO POS
        TEST PRINT
================================
Date: ${DateTime.now().toString().substring(0, 19)}
Printer: ${_connectedDevice?.name ?? 'Unknown'}
Connection: ${_connectedDevice?.connectionType.toString() ?? 'Unknown'}

This is a test print to verify
that your thermal printer is
working correctly.

================================
        TEST SUCCESSFUL
================================


''';

    return await printReceipt(
      receiptText: testReceipt,
      autoCut: true,
      openDrawer: false,
    );
  }

  /// Disconnect from current printer
  Future<void> disconnect() async {
    try {
      if (_bluetoothDevice != null) {
        await _bluetoothDevice!.disconnect();
        _bluetoothDevice = null;
        _bluetoothCharacteristic = null;
      }
      
      if (_networkSocket != null) {
        await _networkSocket!.close();
        _networkSocket = null;
      }
      
      _connectedDevice = null;
      _updateStatus(PrinterStatus.disconnected);
      print('✅ Printer disconnected');
    } catch (e) {
      print('❌ Error disconnecting printer: $e');
    }
  }

  /// Update printer status
  void _updateStatus(PrinterStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Get printer status text
  String getStatusText() {
    switch (_status) {
      case PrinterStatus.disconnected:
        return 'Disconnected';
      case PrinterStatus.connecting:
        return 'Connecting...';
      case PrinterStatus.connected:
        return 'Connected';
      case PrinterStatus.printing:
        return 'Printing...';
      case PrinterStatus.error:
        return 'Error';
      case PrinterStatus.paperOut:
        return 'Paper Out';
      case PrinterStatus.coverOpen:
        return 'Cover Open';
    }
  }

  /// Cleanup resources
  void dispose() {
    disconnect();
    _statusController.close();
  }
}
