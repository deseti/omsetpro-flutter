import 'package:flutter/material.dart';
import '../widgets/insight_widgets.dart';
import '../services/laporan_service.dart';

class InsightDashboardPage extends StatefulWidget {
  const InsightDashboardPage({super.key});

  @override
  State<InsightDashboardPage> createState() => _InsightDashboardPageState();
}

class _InsightDashboardPageState extends State<InsightDashboardPage> {
  String selectedPeriod = 'monthly';
  Map<String, dynamic>? insightData;
  bool isLoading = false;
  String? error;
  late LaporanService _laporanService;

  final Map<String, String> periodLabels = {
    'daily': 'Harian',
    'weekly': 'Mingguan',
    'monthly': 'Bulanan',
    'yearly': 'Tahunan',
  };

  @override
  void initState() {
    super.initState();
    _laporanService = LaporanService();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _laporanService.getDashboardInsights(
        period: selectedPeriod,
      );

      setState(() {
        insightData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart AI Insights'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedPeriod = value;
              });
              _loadInsights();
            },
            itemBuilder: (context) => periodLabels.entries
                .map((entry) => PopupMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    periodLabels[selectedPeriod]!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadInsights,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && insightData == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadInsights,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (insightData == null) {
      return const Center(
        child: Text('Tidak ada data'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan last updated info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard Insights',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  'Update: ${_formatLastUpdated(insightData!['lastUpdated'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Insight Cards Grid
          _buildInsightCards(),
          const SizedBox(height: 24),

          // Sales Comparison Chart
          _buildSalesComparison(),
          const SizedBox(height: 24),

          // Product Insights
          ProductInsightCard(
            productInsights: insightData!['productInsights'],
          ),
          const SizedBox(height: 24),

          // Trend Chart
          TrendChart(
            trendData: List<Map<String, dynamic>>.from(
              insightData!['trendData'],
            ),
          ),
          const SizedBox(height: 24),

          // Profit Insights
          _buildProfitInsights(),
        ],
      ),
    );
  }

  Widget _buildInsightCards() {
    final insights = List<Map<String, dynamic>>.from(
      insightData!['insights'],
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final insight = insights[index];
        return InsightCard(
          title: insight['title'],
          value: insight['value'].toString(),
          trend: insight['trend'],
          trendPercentage: insight['trendPercentage'].toDouble(),
          description: insight['description'],
          type: insight['type'],
          icon: _getIconData(insight['icon']),
        );
      },
    );
  }

  Widget _buildSalesComparison() {
    final salesComparison = insightData!['salesComparison'];

    return SalesComparisonChart(
      currentValue: salesComparison['currentPeriod']['value'].toDouble(),
      previousValue: salesComparison['previousPeriod']['value'].toDouble(),
      currentLabel: salesComparison['currentPeriod']['label'],
      previousLabel: salesComparison['previousPeriod']['label'],
    );
  }

  Widget _buildProfitInsights() {
    final profitInsights = insightData!['profitInsights'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analisa Keuntungan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProfitMetric(
                    'Keuntungan Periode Ini',
                    _formatCurrency(profitInsights['currentProfit'].toDouble()),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildProfitMetric(
                    'Margin Keuntungan',
                    '${profitInsights['profitMargin'].toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: profitInsights['comparison']['trend'] == 'up'
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    profitInsights['comparison']['trend'] == 'up'
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: profitInsights['comparison']['trend'] == 'up'
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      profitInsights['comparison']['description'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: profitInsights['comparison']['trend'] == 'up'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'trending-up':
        return Icons.trending_up;
      case 'shopping-cart':
        return Icons.shopping_cart;
      case 'percent':
        return Icons.percent;
      case 'calculator':
        return Icons.calculate;
      default:
        return Icons.analytics;
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  String _formatLastUpdated(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
