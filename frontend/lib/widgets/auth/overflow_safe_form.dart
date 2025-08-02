import 'package:flutter/material.dart';

/// Widget wrapper untuk form yang aman dari overflow pada mobile
class OverflowSafeForm extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;

  const OverflowSafeForm({
    super.key,
    required this.child,
    this.padding,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isMobile = mediaQuery.size.width < 600;
    
    if (!isMobile) {
      // Untuk tablet/desktop, gunakan layout biasa
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight - keyboardHeight;
        
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: padding ?? EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: keyboardHeight > 0 ? keyboardHeight + 16 : 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: shrinkWrap ? 0 : availableHeight - 32,
            ),
            child: IntrinsicHeight(
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Widget untuk form yang automatically adjust ketika keyboard muncul
class KeyboardAwareForm extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;
  final Curve animationCurve;

  const KeyboardAwareForm({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOut,
  });

  @override
  State<KeyboardAwareForm> createState() => _KeyboardAwareFormState();
}

class _KeyboardAwareFormState extends State<KeyboardAwareForm>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _paddingAnimation;
  double _lastKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _paddingAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    if (keyboardHeight != _lastKeyboardHeight) {
      _lastKeyboardHeight = keyboardHeight;
      _paddingAnimation = Tween<double>(
        begin: _paddingAnimation.value,
        end: keyboardHeight,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ));
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _paddingAnimation,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.only(bottom: _paddingAnimation.value),
          child: widget.child,
        );
      },
    );
  }
}

/// Extension helper untuk MediaQuery
extension MediaQueryExtension on MediaQuery {
  /// Mengecek apakah keyboard sedang tampil
  bool get isKeyboardVisible => viewInsets.bottom > 0;
  
  /// Mendapatkan tinggi keyboard
  double get keyboardHeight => viewInsets.bottom;
  
  /// Mendapatkan available height setelah dikurangi keyboard
  double get availableHeight => size.height - viewInsets.bottom - padding.top - padding.bottom;
}
