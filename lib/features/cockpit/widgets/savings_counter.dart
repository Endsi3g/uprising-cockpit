import 'package:flutter/material.dart';

class SavingsCounter extends StatefulWidget {
  final double targetValue;
  const SavingsCounter({super.key, required this.targetValue});

  @override
  State<SavingsCounter> createState() => _SavingsCounterState();
}

class _SavingsCounterState extends State<SavingsCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousTarget = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _setupAnimation(widget.targetValue);
    _controller.forward();
  }

  @override
  void didUpdateWidget(SavingsCounter old) {
    super.didUpdateWidget(old);
    if (old.targetValue != widget.targetValue) {
      _previousTarget = _animation.value;
      _setupAnimation(widget.targetValue);
      _controller
        ..reset()
        ..forward();
    }
  }

  void _setupAnimation(double target) {
    _animation = Tween<double>(
      begin: _previousTarget,
      end: target,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo,
    ));
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
      builder: (_, __) {
        final value = _animation.value;
        final formatted = _format(value);
        return Text(
          formatted,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1,
          ),
        );
      },
    );
  }

  String _format(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)} k\$ CAD';
    }
    return '${value.toStringAsFixed(0)} \$ CAD';
  }
}
