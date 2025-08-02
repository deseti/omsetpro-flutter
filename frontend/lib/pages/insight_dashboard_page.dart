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
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInsights,
              child: _buildBody(),
            ),
          ),
        ],
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: isMobile ? 12.0 : 16.0,
            right: isMobile ? 12.0 : 16.0,
            top: isMobile ? 8.0 : 16.0,
            bottom: isMobile ? 80.0 : 24.0, // Reduced padding untuk mobile 
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan last updated info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Dashboard Insights',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 18 : null,
                              ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Flexible(
                      child: Text(
                        'Update: ${_formatLastUpdated(insightData!['lastUpdated'])}',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Insight Cards Grid
              _buildInsightCards(),
              SizedBox(height: isMobile ? 16 : 24),

              // Sales Comparison Chart
              _buildSalesComparison(),
              SizedBox(height: isMobile ? 16 : 24),

              // Product Insights
              ProductInsightCard(
                productInsights: insightData!['productInsights'],
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Trend Chart
              TrendChart(
                trendData: List<Map<String, dynamic>>.from(
                  insightData!['trendData'],
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Profit Insights
              _buildProfitInsights(),
              
              // Space tambahan untuk mobile sudah ditangani di padding
              SizedBox(height: isMobile ? 20 : 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightCards() {
    final insights = List<Map<String, dynamic>>.from(
      insightData!['insights'],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if mobile layout
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Mobile: Use ListView instead of GridView to prevent overflow
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: insights.asMap().entries.map((entry) {
              final index = entry.key;
              final insight = entry.value;
              return Container(
                margin: EdgeInsets.only(
                    bottom: index < insights.length - 1 ? 12 : 0),
                child: InsightCard(
                  title: insight['title'],
                  value: insight['value'].toString(),
                  trend: insight['trend'],
                  trendPercentage: insight['trendPercentage'].toDouble(),
                  description: insight['description'],
                  type: insight['type'],
                  icon: _getIconData(insight['icon']),
                ),
              );
            }).toList(),
          );
        } else {
          // Desktop/Tablet: Use GridView as before
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 900 ? 3 : 2,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Card(
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analisa Keuntungan',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isMobile ? 12 : 16),
                if (isMobile)
                  // Mobile: Stack vertically
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProfitMetric(
                        'Keuntungan Periode Ini',
                        _formatCurrency(
                            profitInsights['currentProfit'].toDouble()),
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildProfitMetric(
                        'Margin Keuntungan',
                        '${profitInsights['profitMargin'].toStringAsFixed(1)}%',
                        Colors.blue,
                      ),
                    ],
                  )
                else
                  // Desktop: Side by side
                  Row(
                    children: [
                      Expanded(
                        child: _buildProfitMetric(
                          'Keuntungan Periode Ini',
                          _formatCurrency(
                              profitInsights['currentProfit'].toDouble()),
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
                SizedBox(height: isMobile ? 12 : 16),
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
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
                        size: isMobile ? 20 : 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          profitInsights['comparison']['description'],
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
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
      },
    );
  }

  Widget _buildProfitMetric(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
