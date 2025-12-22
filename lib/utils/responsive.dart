import 'package:flutter/material.dart';

/// Responsive breakpoints en helpers voor tablet/phone layouts
class Responsive {
  // Breakpoints
  static const double phoneMaxWidth = 600;
  static const double tabletMaxWidth = 1200;

  /// Check of het een telefoon is
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < phoneMaxWidth;
  }

  /// Check of het een tablet is
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= phoneMaxWidth && width < tabletMaxWidth;
  }

  /// Check of het een desktop is
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletMaxWidth;
  }

  /// Check of we een brede layout moeten gebruiken (tablet of desktop)
  static bool useWideLayout(BuildContext context) {
    return MediaQuery.of(context).size.width >= phoneMaxWidth;
  }

  /// Krijg het aantal kolommen voor een grid
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= tabletMaxWidth) return 4;
    if (width >= phoneMaxWidth) return 3;
    return 2;
  }

  /// Krijg padding gebaseerd op schermgrootte
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(32);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    }
    return const EdgeInsets.all(16);
  }

  /// Krijg de maximale content breedte
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 900;
    return double.infinity;
  }
}

/// Widget die verschillende layouts toont voor phone/tablet
class ResponsiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (Responsive.useWideLayout(context) && tablet != null) {
      return tablet!;
    }
    return phone;
  }
}

/// Wrapper die content centreert met max breedte op grote schermen
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.getMaxContentWidth(context),
        ),
        child: Padding(
          padding: padding ?? Responsive.getScreenPadding(context),
          child: child,
        ),
      ),
    );
  }
}
