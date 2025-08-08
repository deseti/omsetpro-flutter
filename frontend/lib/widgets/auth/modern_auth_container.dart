import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import '../../widgets/responsive_widgets.dart';

class ModernAuthContainer extends StatelessWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final Widget? backgroundWidget;

  const ModernAuthContainer({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    this.backgroundWidget,
  });

  @override
  Widget build(BuildContext context) {
    const isWeb = kIsWeb;

    // Untuk web, selalu gunakan layout terpusat yang sama
    if (isWeb) {
      return _buildWebLayout(context);
    }

    return ResponsiveLayout(
      mobile: _buildMobileLayout(context),
      tablet: _buildTabletLayout(context),
      desktop: _buildDesktopLayout(context),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _buildBackgroundDecoration(context),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
                minHeight: 400,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: _buildBackgroundDecoration(context),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mediaQuery = MediaQuery.of(context);
              final keyboardHeight = mediaQuery.viewInsets.bottom;
              final isKeyboardVisible = keyboardHeight > 0;

              return CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        isKeyboardVisible ? 8 : 24,
                        16,
                        isKeyboardVisible ? 8 : 24,
                      ),
                      child: Column(
                        mainAxisAlignment: isKeyboardVisible
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header section
                          if (!isKeyboardVisible) ...[
                            _buildHeader(context),
                            const SizedBox(height: 32),
                          ] else ...[
                            _buildCompactHeader(context),
                            const SizedBox(height: 16),
                          ],

                          // Form card - flexible to take available space
                          Flexible(
                            fit: FlexFit.loose,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: double.infinity,
                              ),
                              child: _buildCard(context),
                            ),
                          ),

                          // Bottom spacer - hanya jika tidak ada keyboard
                          if (!isKeyboardVisible) const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: _buildBackgroundDecoration(context),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildCard(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: _buildBackgroundDecoration(context),
        child: Row(
          children: [
            // Left side - Branding/Info
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandingSection(context),
                  ],
                ),
              ),
            ),
            // Right side - Form
            Expanded(
              flex: 2,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(context, compact: true),
                          const SizedBox(height: 32),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool compact = false}) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: compact ? 28 : 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: compact ? 14 : 16,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;
    const isWeb = kIsWeb;

    // Padding yang lebih agresif untuk mobile ketika keyboard aktif
    double cardPadding = 32;
    if (isMobile) {
      cardPadding = keyboardVisible ? 12 : 24;
    }

    // Untuk web, gunakan padding yang konsisten
    if (isWeb) {
      cardPadding = 32;
    }

    return Card(
      elevation: isWeb ? 12 : (isMobile && keyboardVisible ? 2 : 8),
      shadowColor:
          Theme.of(context).colorScheme.shadow.withOpacity(isWeb ? 0.3 : 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
            isWeb ? 16 : (isMobile && keyboardVisible ? 12 : 24)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(
              isWeb ? 16 : (isMobile && keyboardVisible ? 12 : 24)),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBrandingSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo atau icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.point_of_sale,
            size: 40,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'OmsetPro',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sistem manajemen bisnis yang modern dan mudah digunakan. Kelola penjualan, inventory, dan laporan bisnis Anda dengan lebih efisien.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        _buildFeatureList(context),
      ],
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final theme = Theme.of(context);
    final features = [
      {'icon': Icons.inventory_2, 'text': 'Manajemen Produk & Inventory'},
      {'icon': Icons.point_of_sale, 'text': 'Sistem Kasir Modern'},
      {'icon': Icons.analytics, 'text': 'Laporan & Analytics'},
      {'icon': Icons.people, 'text': 'Multi-User & Role Management'},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature['text'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  BoxDecoration _buildBackgroundDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.primaryContainer.withOpacity(0.1),
          colorScheme.secondaryContainer.withOpacity(0.1),
        ],
      ),
    );
  }
}
