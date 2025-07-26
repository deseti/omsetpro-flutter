import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './cart_bottom_sheets.dart';

class CartFloatingButtons extends StatelessWidget {
  final selectedPelanggan;
  final double totalHarga;

  const CartFloatingButtons({
    super.key,
    required this.selectedPelanggan,
    required this.totalHarga,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Customer FAB
        Positioned(
          left: 16,
          top: 100,
          child: FloatingActionButton(
            heroTag: 'customer_fab',
            mini: true,
            backgroundColor: Colors.blue.shade700,
            child: const Icon(Icons.person, color: Colors.white),
            onPressed: () => CartBottomSheets.showCustomerBottomSheet(
              context,
              selectedPelanggan,
            ),
          ),
        ),
        // Promo FAB
        Positioned(
          left: 16,
          top: 160,
          child: FloatingActionButton(
            heroTag: 'promo_fab',
            mini: true,
            backgroundColor: Colors.green.shade700,
            child: const Icon(Icons.local_offer, color: Colors.white),
            onPressed: () => CartBottomSheets.showPromoBottomSheet(context),
          ),
        ),
        // Total FAB
        Positioned(
          left: 16,
          top: 220,
          child: FloatingActionButton(
            heroTag: 'total_fab',
            mini: true,
            backgroundColor: Colors.orange.shade700,
            child: const Icon(Icons.receipt, color: Colors.white),
            onPressed: () => CartBottomSheets.showTotalBottomSheet(
              context,
              totalHarga,
            ),
          ),
        ),
      ],
    );
  }
}
