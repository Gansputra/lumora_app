import 'package:flutter/material.dart';

class AnimatedDotsLoader extends StatefulWidget {
  final String text;
  final Color? color;
  final int speedMs;

  const AnimatedDotsLoader({
    super.key,
    this.text = 'Sedang Mengerjakan',
    this.color,
    this.speedMs = 1200,
  });

  @override
  State<AnimatedDotsLoader> createState() => _AnimatedDotsLoaderState();
}

class _AnimatedDotsLoaderState extends State<AnimatedDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.speedMs),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final dots = (_controller.value * 4).toInt() % 4;
        final dotsText = '.' * dots;
        return Text(
          '${widget.text}$dotsText',
          style: TextStyle(fontSize: 14, color: widget.color ?? Colors.white),
        );
      },
    );
  }
}
