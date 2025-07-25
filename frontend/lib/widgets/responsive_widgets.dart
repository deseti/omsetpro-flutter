import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Responsive layout widget yang otomatis menyesuaikan layout berdasarkan ukuran layar
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.largeDesktop &&
            largeDesktop != null) {
          return largeDesktop!;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.desktop &&
            desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.tablet &&
            tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Master-Detail layout untuk tampilan yang lebih besar
class ResponsiveMasterDetail extends StatelessWidget {
  final Widget master;
  final Widget detail;
  final double masterWidth;
  final bool showMasterInDrawer;

  const ResponsiveMasterDetail({
    super.key,
    required this.master,
    required this.detail,
    this.masterWidth = 300,
    this.showMasterInDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.desktop &&
            !showMasterInDrawer) {
          // Desktop: Side-by-side layout
          return Row(
            children: [
              SizedBox(
                width: masterWidth,
                child: master,
              ),
              const VerticalDivider(width: 1),
              Expanded(child: detail),
            ],
          );
        } else {
          // Mobile/Tablet: Full-width detail with drawer/modal master
          return detail;
        }
      },
    );
  }
}

/// Responsive grid dengan jumlah kolom yang menyesuaikan layar
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double? childAspectRatio;
  final ScrollPhysics? physics;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = AppTheme.spaceMD,
    this.runSpacing = AppTheme.spaceMD,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.childAspectRatio,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        if (constraints.maxWidth >= ResponsiveBreakpoints.desktop) {
          columns = desktopColumns;
        } else if (constraints.maxWidth >= ResponsiveBreakpoints.tablet) {
          columns = tabletColumns;
        } else {
          columns = mobileColumns;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          childAspectRatio: childAspectRatio ?? 1.0,
          physics: physics ?? const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: children,
        );
      },
    );
  }
}

/// Responsive wrap dengan spacing yang konsisten
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final WrapAlignment alignment;
  final double spacing;
  final double runSpacing;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.alignment = WrapAlignment.start,
    this.spacing = AppTheme.spaceSM,
    this.runSpacing = AppTheme.spaceSM,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: alignment,
      spacing: spacing,
      runSpacing: runSpacing,
      children: children,
    );
  }
}

/// Card yang responsif dengan padding dan margin yang menyesuaikan
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = EdgeInsets.all(
      ResponsiveBreakpoints.getResponsiveValue(
        context,
        mobile: AppTheme.spaceMD,
        tablet: AppTheme.spaceLG,
        desktop: AppTheme.spaceLG,
      ),
    );

    final defaultMargin = EdgeInsets.all(
      ResponsiveBreakpoints.getResponsiveValue(
        context,
        mobile: AppTheme.spaceSM,
        tablet: AppTheme.spaceMD,
        desktop: AppTheme.spaceMD,
      ),
    );

    Widget card = Card(
      margin: margin ?? defaultMargin,
      child: Padding(
        padding: padding ?? defaultPadding,
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: () {
          print('DEBUG: ResponsiveCard tapped');
          onTap!();
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: card,
      );
    }

    return card;
  }
}

/// Container dengan padding responsif
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? width;
  final double? height;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPadding = EdgeInsets.symmetric(
      horizontal: ResponsiveBreakpoints.getResponsiveValue(
        context,
        mobile: AppTheme.spaceMD,
        tablet: AppTheme.spaceLG,
        desktop: AppTheme.spaceXL,
      ),
      vertical: ResponsiveBreakpoints.getResponsiveValue(
        context,
        mobile: AppTheme.spaceMD,
        tablet: AppTheme.spaceLG,
        desktop: AppTheme.spaceLG,
      ),
    );

    return Container(
      width: width,
      height: height,
      padding: padding ?? defaultPadding,
      margin: margin,
      color: color,
      child: child,
    );
  }
}

/// Spacing widget yang menyesuaikan ukuran berdasarkan device
class ResponsiveSpacing extends StatelessWidget {
  final double mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final bool isVertical;

  const ResponsiveSpacing({
    super.key,
    required this.mobileSize,
    this.tabletSize,
    this.desktopSize,
    this.isVertical = true,
  });

  const ResponsiveSpacing.horizontal({
    super.key,
    required this.mobileSize,
    this.tabletSize,
    this.desktopSize,
  }) : isVertical = false;

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveBreakpoints.getResponsiveValue(
      context,
      mobile: mobileSize,
      tablet: tabletSize ?? mobileSize,
      desktop: desktopSize ?? tabletSize ?? mobileSize,
    );

    return isVertical ? SizedBox(height: size) : SizedBox(width: size);
  }
}

/// Utility untuk mendapatkan cross axis count yang responsif
class ResponsiveUtils {
  static int getGridCrossAxisCount(
    BuildContext context, {
    int mobileCount = 1,
    int tabletCount = 2,
    int desktopCount = 3,
    int largeDesktopCount = 4,
  }) {
    return ResponsiveBreakpoints.getResponsiveValue(
      context,
      mobile: mobileCount.toDouble(),
      tablet: tabletCount.toDouble(),
      desktop: desktopCount.toDouble(),
      largeDesktop: largeDesktopCount.toDouble(),
    ).toInt();
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    return ResponsiveBreakpoints.getResponsiveValue(
      context,
      mobile: mobileSize,
      tablet: tabletSize ?? mobileSize * 1.1,
      desktop: desktopSize ?? tabletSize ?? mobileSize * 1.2,
    );
  }

  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (context.isDesktop) {
      return desktop ??
          tablet ??
          mobile ??
          const EdgeInsets.all(AppTheme.spaceLG);
    } else if (context.isTablet) {
      return tablet ?? mobile ?? const EdgeInsets.all(AppTheme.spaceMD);
    } else {
      return mobile ?? const EdgeInsets.all(AppTheme.spaceMD);
    }
  }
}
