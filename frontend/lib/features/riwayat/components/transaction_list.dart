import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/riwayat_transaksi_model.dart';
import '../../../providers/riwayat_transaksi_provider.dart';
import '../../../services/riwayat_transaksi_service.dart';
import '../widgets/empty_transaction_state.dart';
import '../widgets/transaksi_card.dart';
import '../dialogs/transaksi_detail_dialog.dart';
import '../dialogs/shipping_info_dialog.dart';

class TransactionList extends ConsumerStatefulWidget {
  final List<RiwayatTransaksi> transaksiList;
  final PaginationInfo? pagination;

  const TransactionList({
    super.key,
    required this.transaksiList,
    this.pagination,
  });

  @override
  ConsumerState<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends ConsumerState<TransactionList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });

    await ref.read(riwayatTransaksiProvider.notifier).loadMore();

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transaksiList.isEmpty) {
      return const EmptyTransactionState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(riwayatTransaksiProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: widget.transaksiList.length +
            (widget.pagination?.hasMore == true ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == widget.transaksiList.length) {
            // Loading indicator for load more
            return _isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }

          final transaksi = widget.transaksiList[index];
          return TransaksiCard(
            transaksi: transaksi,
            dark: true,
            onTap: () => _showDetailDialog(transaksi),
            onAddShippingInfo:
                transaksi.isDelivery && !transaksi.hasShippingInfo
                    ? () => _showShippingDialog(transaksi)
                    : null,
          );
        },
      ),
    );
  }

  void _showDetailDialog(RiwayatTransaksi transaksi) {
    showDialog(
      context: context,
      builder: (context) => TransaksiDetailDialog(transaksi: transaksi),
    );
  }

  void _showShippingDialog(RiwayatTransaksi transaksi) {
    showDialog(
      context: context,
      builder: (context) => ShippingInfoDialog(
        transaksi: transaksi,
        onSubmit: (resi, kurir) async {
          try {
            final service = ref.read(riwayatTransaksiServiceProvider);
            await service.updateShippingInfo(
              transaksiId: transaksi.id,
              nomorResi: resi,
              namaKurir: kurir,
            );

            // Refresh data
            ref.read(riwayatTransaksiProvider.notifier).refresh();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Info pengiriman berhasil disimpan!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Gagal menyimpan info pengiriman: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
