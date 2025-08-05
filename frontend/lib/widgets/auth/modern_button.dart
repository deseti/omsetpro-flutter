import 'package:flutter/material.dart';

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ModernButtonStyle style;
  final IconData? icon;
  final bool fullWidth;
  final double? height;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.style = ModernButtonStyle.primary,
    this.icon,
    this.fullWidth = true,
    this.height,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    Color foregroundColor;
    Color shadowColor;

    switch (widget.style) {
      case ModernButtonStyle.primary:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        shadowColor = colorScheme.primary.withOpacity(0.3);
        break;
      case ModernButtonStyle.secondary:
        backgroundColor = colorScheme.secondary;
        foregroundColor = colorScheme.onSecondary;
        shadowColor = colorScheme.secondary.withOpacity(0.3);
        break;
      case ModernButtonStyle.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = colorScheme.primary;
        shadowColor = Colors.transparent;
        break;
      case ModernButtonStyle.text:
        backgroundColor = Colors.transparent;
        foregroundColor = colorScheme.primary;
        shadowColor = Colors.transparent;
        break;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onPressed != null && !widget.isLoading
                ? _onTapDown
                : null,
            onTapUp:
                widget.onPressed != null && !widget.isLoading ? _onTapUp : null,
            onTapCancel: widget.onPressed != null && !widget.isLoading
                ? _onTapCancel
                : null,
            child: Container(
              width: widget.fullWidth ? double.infinity : null,
              height: widget.height ?? 56,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: widget.style == ModernButtonStyle.outline
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
                boxShadow: widget.style != ModernButtonStyle.text &&
                        widget.style != ModernButtonStyle.outline
                    ? [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: _isPressed ? 4 : 8,
                          offset: Offset(0, _isPressed ? 2 : 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed != null && !widget.isLoading
                      ? widget.onPressed
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: widget.fullWidth
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      children: [
                        if (widget.isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                foregroundColor,
                              ),
                            ),
                          )
                        else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: foregroundColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (!widget.isLoading)
                          Flexible(
                            child: Text(
                              widget.text,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: foregroundColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (widget.isLoading) ...[
                          const SizedBox(width: 12),
                          Text(
                            'Loading...',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: foregroundColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum ModernButtonStyle {
  primary,
  secondary,
  outline,
  text,
}
