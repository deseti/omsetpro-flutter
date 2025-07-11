import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO; // 1. Import socket_io_client
import '../../../providers/laporan_provider.dart';
import '../../../utils/laporan_refresh_helper.dart';
import '../../../utils/api_config.dart'; // Import ApiConfig
import '../widgets/summary_cards.dart';
import '../widgets/charts.dart';
import '../widgets/filter_widgets.dart';
import '../widgets/ai_chat_widget.dart';

// 2. Ubah menjadi ConsumerStatefulWidget agar bisa menggunakan initState dan dispose
class LaporanDashboardScreen extends ConsumerStatefulWidget {
  const LaporanDashboardScreen({super.key});

  @override
  ConsumerState<LaporanDashboardScreen> createState() => _LaporanDashboardScreenState();
}

class _LaporanDashboardScreenState extends ConsumerState<LaporanDashboardScreen> {
  IO.Socket? socket; // 3. Deklarasikan variabel socket

  @override
  void initState() {
    super.initState();
    // 4. Panggil fungsi untuk menginisialisasi koneksi WebSocket
    _initSocket();
  }

  // 5. Fungsi untuk setup dan koneksi ke server WebSocket
  void _initSocket() {
    // Gunakan URL dari ApiConfig agar konsisten
    final url = ApiConfig.baseUrl; 
    
    // Buat koneksi socket
    socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    // Handle saat berhasil terhubung
    socket!.onConnect((_) {
      print('✅ Real-time terhubung ke server laporan!');
    });

    // 6. INI BAGIAN PALING PENTING: Mendengarkan event 'laporan_updated' dari server
    socket!.on('laporan_updated', (data) {
      print('⚡️ Menerima update laporan real-time dari server: $data');
      
      // Saat ada update, panggil helper untuk me-refresh semua data laporan
      LaporanRefreshHelper.refreshAllLaporanData(ref);
    });

    // Handle saat koneksi terputus
    socket!.onDisconnect((_) => print('❌ Koneksi real-time terputus.'));
  }

  @override
  void dispose() {
    // 7. Putuskan koneksi socket saat halaman ditutup untuk mencegah memory leak
    socket?.dispose();
    super.dispose();
  }

  // --- Sisa kode build tidak ada yang berubah ---
  @override
  Widget build(BuildContext context) {
    // Initialize global auto-refresh timer
    ref.watch(globalAutoRefreshProvider);
    
    final dashboardAsync = ref.watch(dashboardProvider);
    final dateRange = ref.watch(dateRangeProvider);
    final autoRefreshEnabled = ref.watch(autoRefreshEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Laporan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              autoRefreshEnabled ? Icons.autorenew : Icons.pause_circle_outline,
              color: autoRefreshEnabled ? Colors.green : Colors.orange,
            ),
            onPressed: () {
              if (autoRefreshEnabled) {
                LaporanRefreshHelper.disableAutoRefresh(ref);
              } else {
                LaporanRefreshHelper.enableAutoRefresh(ref);
              }
            },
            tooltip: autoRefreshEnabled ? 'Disable Auto-Refresh' : 'Enable Auto-Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            onPressed: () => Navigator.of(context).pushNamed('/laporan-detail'),
            tooltip: 'Detail Laporan',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => LaporanRefreshHelper.refreshAllLaporanData(ref),
            tooltip: 'Manual Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          LaporanRefreshHelper.refreshAllLaporanData(ref);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterInfo(dateRange),
              const SizedBox(height: 16),
              dashboardAsync.when(
                data: (dashboardData) => _buildDashboardContent(dashboardData),
                loading: () => _buildLoadingState(),
                error: (error, stackTrace) => _buildErrorState(error.toString(), ref),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed('/laporan-detail'),
        icon: const Icon(Icons.analytics),
        label: const Text('Detail Laporan'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // ... (semua fungsi _build... tetap sama, tidak perlu diubah)
  Widget _buildFilterInfo(DateRange dateRange) {
    return Consumer(
      builder: (context, ref, child) {
        final autoRefreshEnabled = ref.watch(autoRefreshEnabledProvider);
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.date_range,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Periode: ${DateFormat('dd MMM yyyy').format(dateRange.startDate)} - ${DateFormat('dd MMM yyyy').format(dateRange.endDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    autoRefreshEnabled ? Icons.autorenew : Icons.pause_circle_outline,
                    size: 14,
                    color: autoRefreshEnabled ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    autoRefreshEnabled ? 'Auto-refresh: ON (30s)' : 'Auto-refresh: OFF',
                    style: TextStyle(
                      fontSize: 12,
                      color: autoRefreshEnabled ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent(dashboardData) {
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
        _buildSummaryCards(dashboardData.ringkasan),
        const SizedBox(height: 24),
        const Text(
          'Grafik Penjualan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SalesChart(
          data: dashboardData.statistikTransaksi,
          title: 'Trend Penjualan Harian',
        ),
        const SizedBox(height: 16),
        ProductSalesChart(
          data: dashboardData.produkTerlaris,
          title: 'Top 5 Produk Terlaris',
        ),
        const SizedBox(height: 24),
        const Text(
          'Detail Analisis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailedStats(dashboardData),
        const SizedBox(height: 24),
        const Text(
          'Asisten AI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        const AiChatWidget(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryCards(ringkasan) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Total Omzet',
                value: CurrencyFormatter.format(ringkasan.totalOmzet),
                icon: Icons.attach_money,
                color: Colors.green,
                subtitle: '${ringkasan.totalTransaksi} transaksi',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Total Laba',
                value: CurrencyFormatter.format(ringkasan.totalLaba),
                icon: Icons.trending_up,
                color: Colors.blue,
                subtitle: 'Margin ${((ringkasan.totalLaba / (ringkasan.totalOmzet == 0 ? 1 : ringkasan.totalOmzet)) * 100).toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Barang Terjual',
                value: NumberFormatter.format(ringkasan.totalBarangTerjual),
                icon: Icons.shopping_cart,
                color: Colors.orange,
                subtitle: '${ringkasan.totalBarangTerjual} unit',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Rata-rata/Transaksi',
                value: CurrencyFormatter.format(ringkasan.rataRataTransaksi),
                icon: Icons.calculate,
                color: Colors.purple,
                subtitle: 'Per transaksi',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedStats(dashboardData) {
    return Column(
      children: [
        QuickStatsCard(
          title: 'Analisis Laba Rugi',
          items: [
            QuickStatItem(
              label: 'Total Pendapatan',
              value: CurrencyFormatter.format(dashboardData.labaRugi.totalPendapatan),
              color: Colors.green,
            ),
            QuickStatItem(
              label: 'HPP (Harga Pokok Penjualan)',
              value: CurrencyFormatter.format(dashboardData.labaRugi.totalHPP),
              color: Colors.red,
            ),
            QuickStatItem(
              label: 'Laba Bersih',
              value: CurrencyFormatter.format(dashboardData.labaRugi.totalLaba),
              color: Colors.blue,
            ),
            QuickStatItem(
              label: 'Margin Keuntungan',
              value: '${dashboardData.labaRugi.margin.toStringAsFixed(2)}%',
              color: Colors.purple,
            ),
          ],
        ),
        const SizedBox(height: 16),
        QuickStatsCard(
          title: 'Produk Terlaris',
          items: dashboardData.produkTerlaris.take(5).map<QuickStatItem>((produk) {
            return QuickStatItem(
              label: produk.namaProduk,
              value: '${produk.totalTerjual} unit',
              color: Colors.blue,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
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
          Text(
            'Terjadi Kesalahan',
            style: const TextStyle(
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
            onPressed: () => ref.refresh(dashboardProvider),
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

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const FilterDialog(),
    );
  }
}
