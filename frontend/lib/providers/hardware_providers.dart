// lib/providers/hardware_providers.dart
// Providers untuk hardware management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hardware/hardware_manager_service.dart';
import '../services/hardware/hardware_detection_service.dart';
import '../services/hardware/thermal_printer_service.dart';
import '../services/hardware/barcode_scanner_service.dart';

// Hardware Manager Provider
final hardwareManagerProvider = Provider<HardwareManagerService>((ref) {
  final manager = HardwareManagerService();
  // Initialize asynchronously if not already done
  if (!manager.isInitialized) {
    manager.initialize().catchError((e) {
      print('⚠️ Hardware Manager initialization error in provider: $e');
    });
  }
  return manager;
});

// Hardware Devices Stream Provider
final hardwareDevicesProvider = StreamProvider<List<HardwareDevice>>((ref) {
  final manager = ref.watch(hardwareManagerProvider);
  if (!manager.isInitialized) {
    return Stream.value(<HardwareDevice>[]);
  }
  return manager.devicesStream;
});

// Hardware Notifications Stream Provider
final hardwareNotificationsProvider = StreamProvider<String>((ref) {
  final manager = ref.watch(hardwareManagerProvider);
  if (!manager.isInitialized) {
    return Stream.value('Hardware initializing...');
  }
  return manager.notificationStream;
});

// Printer Status Stream Provider
final printerStatusProvider = StreamProvider<PrinterStatus>((ref) {
  final manager = ref.watch(hardwareManagerProvider);
  if (!manager.isInitialized) {
    return Stream.value(PrinterStatus.disconnected);
  }
  return manager.printerService.statusStream;
});

// Scanner Status Stream Provider
final scannerStatusProvider = StreamProvider<ScannerStatus>((ref) {
  final manager = ref.watch(hardwareManagerProvider);
  if (!manager.isInitialized) {
    return Stream.value(ScannerStatus.disconnected);
  }
  return manager.scannerService.statusStream;
});

// Barcode Scan Stream Provider
final barcodeStreamProvider = StreamProvider<BarcodeResult>((ref) {
  final manager = ref.watch(hardwareManagerProvider);
  if (!manager.isInitialized) {
    return const Stream.empty();
  }
  return manager.scannerService.barcodeStream;
});

// Connected Devices Provider
final connectedDevicesProvider = Provider<Map<HardwareType, HardwareDevice?>>((ref) {
  final manager = ref.watch(hardwareManagerProvider);
  if (!manager.isInitialized) {
    return <HardwareType, HardwareDevice?>{};
  }
  return manager.getConnectedDevices();
});

// Hardware Status Provider
final hardwareStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final manager = ref.watch(hardwareManagerProvider);
  return manager.getHardwareStatus();
});

// Specific Device Type Providers
final printersProvider = Provider<List<HardwareDevice>>((ref) {
  final devices = ref.watch(hardwareDevicesProvider);
  return devices.when(
    data: (devices) => devices.where((d) => d.type == HardwareType.thermalPrinter).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final scannersProvider = Provider<List<HardwareDevice>>((ref) {
  final devices = ref.watch(hardwareDevicesProvider);
  return devices.when(
    data: (devices) => devices.where((d) => d.type == HardwareType.barcodeScanner).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Hardware Connection Status Providers
final isPrinterConnectedProvider = Provider<bool>((ref) {
  final status = ref.watch(printerStatusProvider);
  return status.when(
    data: (status) => status == PrinterStatus.connected || status == PrinterStatus.printing,
    loading: () => false,
    error: (_, __) => false,
  );
});

final isScannerConnectedProvider = Provider<bool>((ref) {
  final status = ref.watch(scannerStatusProvider);
  return status.when(
    data: (status) => status == ScannerStatus.connected || status == ScannerStatus.scanning,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Hardware Initialization Provider
final hardwareInitializationProvider = FutureProvider<bool>((ref) async {
  final manager = ref.watch(hardwareManagerProvider);
  try {
    await manager.initialize();
    return true;
  } catch (e) {
    return false;
  }
});

// Auto-connect Provider
final autoConnectProvider = FutureProvider<void>((ref) async {
  final manager = ref.watch(hardwareManagerProvider);
  await manager.autoConnectSavedDevices();
});
