import 'dart:async';

import 'package:flutter/material.dart';

/// 脉动点动画组件，用于表示匹配/加载状态
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  final Duration? delay;

  const PulsingDot({
    super.key,
    required this.color,
    this.size = 6.0,
    this.delay,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.2)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_controller);

    // 添加延迟
    if (widget.delay != null) {
      Future.delayed(widget.delay!, () {
        if (mounted) {
          _controller.repeat();
        }
      });
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
