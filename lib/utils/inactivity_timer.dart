import 'package:flutter/material.dart';

class InactivityTimer extends StatefulWidget {
  final Widget child;
  final bool enableLogging;

  const InactivityTimer({
    super.key,
    required this.child,
    this.enableLogging = false,
  });

  @override
  State<InactivityTimer> createState() => _InactivityTimerState();
}

class _InactivityTimerState extends State<InactivityTimer> {
  @override
  Widget build(BuildContext context) {
    // Just wrap the child, no inactivity monitoring
    return widget.child;
  }
}
