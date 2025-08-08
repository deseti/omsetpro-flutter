import 'package:flutter/material.dart';

class HardwareDialogs {
  static void showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hardware Setup Help'),
        content: const SingleChildScrollView(
          child: Text(
            'Hardware Setup Guide:\n\n'
            '1. Thermal Printers:\n'
            '   • Connect via USB, Bluetooth, or WiFi\n'
            '   • Supported: Epson, Star, Citizen, Bixolon, Sunmi\n'
            '   • Test print to verify functionality\n\n'
            '2. Barcode Scanners:\n'
            '   • USB HID scanners work automatically\n'
            '   • Bluetooth scanners need pairing first\n'
            '   • Test scan to verify functionality\n\n'
            '3. Cash Drawers:\n'
            '   • Connect to thermal printer (RJ11/RJ12)\n'
            '   • Opens automatically with printer commands\n\n'
            'For technical support, contact OmsetPro team.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static void showHardwareInfo(BuildContext context, dynamic hardwareStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hardware Information'),
        content: SingleChildScrollView(
          child: Text(hardwareStatus.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static void showTestResults(
      BuildContext context, Map<dynamic, bool> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hardware Test Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: results.entries.map((entry) {
            return ListTile(
              leading: Icon(
                entry.value ? Icons.check_circle : Icons.error,
                color: entry.value ? Colors.green : Colors.red,
              ),
              title: Text(entry.key.toString().split('.').last),
              subtitle: Text(entry.value ? 'Pass' : 'Fail'),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
