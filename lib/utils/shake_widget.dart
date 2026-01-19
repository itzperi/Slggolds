import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeCount;
  final double shakeOffset;

  const ShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.shakeCount = 3,
    this.shakeOffset = 10,
  });

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
    HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final double sineValue =
            ((_controller.value * widget.shakeCount * 2 * math.pi) / 2);
        return Transform.translate(
          offset: Offset(widget.shakeOffset * (sineValue > 0 ? 1 : -1) * (1 - _controller.value) * (sineValue.abs()).clamp(0, 1) * math.sin(sineValue), 0),
          // Simplified sine-based shake
          // offset: Offset(widget.shakeOffset * (sineValue).sin(), 0),
          child: child,
        );
      },
      // Using a simpler version for better clarity
      // builder: (context, child) {
      //   final double offset = widget.shakeOffset * (1 - _controller.value) * (widget.shakeCount * 2 * 3.14159 * _controller.value).sin();
      //   return Transform.translate(
      //     offset: Offset(offset, 0),
      //     child: child,
      //   );
      // },
    );
  }
}

// Improved version with Animation
class SineShakeWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double shakeCount;
  final double shakeOffset;

  const SineShakeWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.shakeCount = 3,
    this.shakeOffset = 10,
  });

  @override
  State<SineShakeWidget> createState() => SineShakeWidgetState();
}

class SineShakeWidgetState extends State<SineShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
    HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final offset = widget.shakeOffset * (1 - _controller.value) * math.sin(widget.shakeCount * 2 * math.pi * _controller.value);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
    );
  }
}
