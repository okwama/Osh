import 'package:flutter/material.dart';
import 'package:woosh/utils/app_theme.dart';

// A Card with cream background and gradient border
class CreamGradientCard extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;

  const CreamGradientCard({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(8.0),
    this.elevation = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: goldGradient,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: elevation,
                  offset: Offset(0, elevation / 2),
                )
              ]
            : null,
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          color: appBackground,
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
