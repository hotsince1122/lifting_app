import 'package:flutter/material.dart';

class InsertedSetAnimation extends StatefulWidget {
  const InsertedSetAnimation({
    required this.child,
    this.onCompleted,
    super.key,
  });

  final Widget child;
  final VoidCallback? onCompleted;

  @override
  State<InsertedSetAnimation> createState() => _InsertedSetAnimationState();
}

class _InsertedSetAnimationState extends State<InsertedSetAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _size;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _size = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1, curve: Curves.easeOut),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FadeTransition(
        opacity: _fade,
        child: SizeTransition(
          sizeFactor: _size,
          axisAlignment: -1,
          child: SlideTransition(
            position: _slide,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}