import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/riwayat_transaksi_provider.dart';
import '../../theme/app_colors.dart';
import 'components/filter_section.dart';
import 'components/transaction_list.dart';
import 'widgets/error_transaction_widget.dart';

class RiwayatTransaksiPage extends ConsumerWidget {
  const RiwayatTransaksiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riwayatState = ref.watch(riwayatTransaksiProvider);
    final pagination = ref.watch(riwayatPaginationProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(riwayatTransaksiProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          const FilterSection(),
          Expanded(
            child: riwayatState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  ErrorTransactionWidget(error: error.toString()),
              data: (transaksiList) => TransactionList(
                transaksiList: transaksiList,
                pagination: pagination,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
