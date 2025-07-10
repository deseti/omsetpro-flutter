import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/laporan_provider.dart';
import '../../../models/laporan/laporan_models.dart';
import '../widgets/summary_cards.dart';
import '../widgets/filter_widgets.dart';

class DetailLaporanScreen extends ConsumerWidget {
  const DetailLaporanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Detail Laporan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Ringkasan'),
              Tab(text: 'Produk'),
              Tab(text: 'Transaksi'),
              Tab(text: 'Laba Rugi'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Quick Filter Chips
            Container(
              color: Colors.grey[50],
              child: const QuickFilterChips(),
            ),
            const SizedBox(height: 8),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  _RingkasanTab(),
                  _ProdukTab(),
                  _TransaksiTab(),
                  _LabaRugiTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingkasanTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringkasanAsync = ref.watch(ringkasanPenjualanProvider);
    final dateRange = ref.watch(dateRangeProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(ringkasanPenjualanProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodeInfo(dateRange),
            const SizedBox(height: 16),
            ringkasanAsync.when(
              data: (ringkasan) => _buildRingkasanContent(ringkasan),
              loading: () => _buildLoadingState(),
              error: (error, stackTrace) => _buildErrorState(error.toString(), ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingkasanContent(RingkasanPenjualan ringkasan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Penjualan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Total Omzet',
          value: CurrencyFormatter.format(ringkasan.totalOmzet),
          icon: Icons.attach_money,
          color: Colors.green,
          subtitle: 'Total penjualan dalam periode',
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Total Laba',
          value: CurrencyFormatter.format(ringkasan.totalLaba),
          icon: Icons.trending_up,
          color: Colors.blue,
          subtitle: 'Keuntungan bersih',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total Transaksi',
                value: NumberFormatter.format(ringkasan.totalTransaksi),
                icon: Icons.receipt,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Barang Terjual',
                value: NumberFormatter.format(ringkasan.totalBarangTerjual),
                icon: Icons.shopping_cart,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: 'Rata-rata per Transaksi',
          value: CurrencyFormatter.format(ringkasan.rataRataTransaksi),
          icon: Icons.calculate,
          color: Colors.teal,
          subtitle: 'Nilai rata-rata setiap transaksi',
        ),
      ],
    );
  }

  Widget _buildPeriodeInfo(DateRange dateRange) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.date_range,
            size: 16,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(
            'Periode: ${DateFormat('dd MMM yyyy').format(dateRange.startDate)} - ${DateFormat('dd MMM yyyy').format(dateRange.endDate)}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(ringkasanPenjualanProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProdukTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produkAsync = ref.watch(produkTerlarisProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(produkTerlarisProvider);
      },
      child: produkAsync.when(
        data: (produkList) => _buildProdukContent(produkList),
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(error.toString(), ref),
      ),
    );
  }

  Widget _buildProdukContent(List<ProdukTerlaris> produkList) {
    if (produkList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada data produk',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: produkList.length,
      itemBuilder: (context, index) {
        final produk = produkList[index];
        final rank = index + 1;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getRankColor(rank),
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              produk.namaProduk,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${produk.totalTerjual} unit terjual'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Omzet: ${CurrencyFormatter.format(produk.totalOmzet)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Laba: ${CurrencyFormatter.format(produk.totalLaba)}'),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  CurrencyFormatter.format(produk.totalOmzet),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${produk.totalTerjual} unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(produkTerlarisProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransaksiTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaksiAsync = ref.watch(statistikTransaksiProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(statistikTransaksiProvider);
      },
      child: transaksiAsync.when(
        data: (transaksiList) => _buildTransaksiContent(transaksiList),
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(error.toString(), ref),
      ),
    );
  }

  Widget _buildTransaksiContent(List<StatistikTransaksi> transaksiList) {
    if (transaksiList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Tidak ada data transaksi',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Sort by date descending (newest first)
    final sortedList = List<StatistikTransaksi>.from(transaksiList);
    sortedList.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final transaksi = sortedList[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.blue,
              ),
            ),
            title: Text(
              DateFormat('EEEE, dd MMMM yyyy').format(transaksi.dateTime),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.receipt, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${transaksi.jumlahTransaksi} transaksi'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Omzet: ${CurrencyFormatter.format(transaksi.totalOmzet)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Laba: ${CurrencyFormatter.format(transaksi.totalLaba)}'),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  CurrencyFormatter.format(transaksi.totalOmzet),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${transaksi.jumlahTransaksi} trx',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(statistikTransaksiProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabaRugiTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labaRugiAsync = ref.watch(laporanLabaRugiProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(laporanLabaRugiProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: labaRugiAsync.when(
          data: (labaRugi) => _buildLabaRugiContent(labaRugi),
          loading: () => _buildLoadingState(),
          error: (error, stackTrace) => _buildErrorState(error.toString(), ref),
        ),
      ),
    );
  }

  Widget _buildLabaRugiContent(LaporanLabaRugi labaRugi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Laporan Laba Rugi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Total Pendapatan
        SummaryCard(
          title: 'Total Pendapatan',
          value: CurrencyFormatter.format(labaRugi.totalPendapatan),
          icon: Icons.attach_money,
          color: Colors.green,
          subtitle: 'Total penjualan kotor',
        ),
        const SizedBox(height: 12),
        
        // HPP
        SummaryCard(
          title: 'HPP (Harga Pokok Penjualan)',
          value: CurrencyFormatter.format(labaRugi.totalHPP),
          icon: Icons.remove_circle_outline,
          color: Colors.red,
          subtitle: 'Total biaya produk terjual',
        ),
        const SizedBox(height: 12),
        
        // Laba Bersih
        SummaryCard(
          title: 'Laba Bersih',
          value: CurrencyFormatter.format(labaRugi.totalLaba),
          icon: Icons.trending_up,
          color: Colors.blue,
          subtitle: 'Pendapatan - HPP',
        ),
        const SizedBox(height: 12),
        
        // Margin Keuntungan
        SummaryCard(
          title: 'Margin Keuntungan',
          value: '${labaRugi.margin.toStringAsFixed(2)}%',
          icon: Icons.percent,
          color: Colors.purple,
          subtitle: 'Persentase keuntungan',
        ),
        const SizedBox(height: 24),
        
        // Analisis Detail
        const Text(
          'Analisis Detail',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        QuickStatsCard(
          title: 'Breakdown Keuangan',
          items: [
            QuickStatItem(
              label: 'Total Penjualan',
              value: CurrencyFormatter.format(labaRugi.totalPenjualan),
              color: Colors.green,
            ),
            QuickStatItem(
              label: 'Harga Pokok Penjualan',
              value: CurrencyFormatter.format(labaRugi.totalHPP),
              color: Colors.red,
            ),
            QuickStatItem(
              label: 'Laba Kotor',
              value: CurrencyFormatter.format(labaRugi.totalLaba),
              color: Colors.blue,
            ),
            QuickStatItem(
              label: 'Margin (%)',
              value: '${labaRugi.margin.toStringAsFixed(2)}%',
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Terjadi Kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.refresh(laporanLabaRugiProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
