import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart' as AppProviders;
import '../../../widgets/responsive_widgets.dart';
import '../../../theme/app_theme.dart';
import './produk_card_widget.dart';
import '../services/product_filter_helper.dart';

class ProductGridWidget extends ConsumerWidget {
  final int cabangId;
  final TextEditingController searchController;
  final String searchQuery;

  const ProductGridWidget({
    super.key,
    required this.cabangId,
    required this.searchController,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOfflineMode = ref.watch(AppProviders.offlineModeProvider);

    return Column(
      children: [
        // Search Bar
        ResponsiveContainer(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Cari produk atau scan barcode...',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
        // Product Grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                  AppProviders.produkListWithOfflineProvider(cabangId));
              ref.read(AppProviders.cartProvider.notifier).state = [];
              ref.read(AppProviders.selectedPelangganProvider.notifier).state =
                  null;
            },
            child: Consumer(
              builder: (context, ref, _) {
                final produkAsync = ref.watch(
                    AppProviders.produkListWithOfflineProvider(cabangId));
                return produkAsync.when(
                  data: (produkList) {
                    final filteredProducts = ProductFilterHelper.filterProducts(
                        produkList, searchQuery);
                    return Column(
                      children: [
                        // Offline Mode Indicator
                        if (isOfflineMode)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppTheme.spaceMD),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(AppTheme.radiusMD),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.offline_bolt,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                ),
                                const SizedBox(width: AppTheme.spaceSM),
                                Expanded(
                                  child: Text(
                                    'Mode Offline - Data dari cache lokal',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onTertiaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Products Grid
                        Expanded(
                          child: ResponsiveGrid(
                            mobileColumns:
                                ResponsiveUtils.getGridCrossAxisCount(
                              context,
                              mobileCount: 2,
                              tabletCount: 3,
                              desktopCount: 4,
                            ),
                            tabletColumns:
                                ResponsiveUtils.getGridCrossAxisCount(
                              context,
                              mobileCount: 2,
                              tabletCount: 3,
                              desktopCount: 4,
                            ),
                            desktopColumns:
                                ResponsiveUtils.getGridCrossAxisCount(
                              context,
                              mobileCount: 2,
                              tabletCount: 3,
                              desktopCount: 4,
                            ),
                            childAspectRatio: 0.75,
                            children: filteredProducts
                                .map((product) =>
                                    ProdukCardWidget(produk: product))
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: AppTheme.spaceMD),
                        Text(
                          'Terjadi kesalahan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.spaceSM),
                        Text(
                          'Error: $err',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
