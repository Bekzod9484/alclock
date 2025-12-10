import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? color;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? AppSizes.radiusMedium,
                ),
                color: widget.color ?? AppColors.gradientStart,
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: AppColors.shadowDark,
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.shadowDark,
                          offset: const Offset(4, 4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: AppColors.shadowLight,
                          offset: const Offset(-4, -4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

