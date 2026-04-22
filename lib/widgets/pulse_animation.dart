import 'package:flutter/material.dart';

class PulseAnimation extends StatefulWidget {
  final Widget child;
  final bool active;

  const PulseAnimation({super.key, required this.child, required this.active});

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.0, end: 10.0).animate(_controller);
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
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
          decoration: BoxDecoration(
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: _animation.value * 2,
                      spreadRadius: _animation.value,
                    )
                  ]
                : [],
          ),
          child: widget.child,
        );
      },
    );
  }
}
