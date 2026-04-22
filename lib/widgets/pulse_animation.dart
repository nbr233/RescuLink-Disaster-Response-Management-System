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
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _opacityAnim = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.active)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _opacityAnim,
                builder: (_, __) => Container(
                  color: Colors.red.withOpacity(_opacityAnim.value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
