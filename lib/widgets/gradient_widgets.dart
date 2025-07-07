import 'package:flutter/material.dart';
import 'package:woosh/utils/app_theme.dart';

// A FloatingActionButton with gold gradient
class GradientFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String? tooltip;
  final double elevation;

  const GradientFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.elevation = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GradientDecoration.goldCircular(),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        elevation: elevation,
        backgroundColor: Colors.transparent,
        child: icon,
      ),
    );
  }
}

// A LinearProgressIndicator with gold gradient
class GradientLinearProgressIndicator extends StatelessWidget {
  final double? value;
  final double height;
  final double borderRadius;

  const GradientLinearProgressIndicator({
    super.key,
    this.value,
    this.height = 6.0,
    this.borderRadius = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Background
            Container(
              width: double.infinity,
              height: height,
              color: lightGrey,
            ),
            // Progress with gradient
            FractionallySizedBox(
              widthFactor: value ?? 0,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: goldGradient,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A CircularProgressIndicator with gold gradient
class GradientCircularProgressIndicator extends StatelessWidget {
  final double? value;
  final double strokeWidth;
  final double radius;

  const GradientCircularProgressIndicator({
    super.key,
    this.value,
    this.strokeWidth = 4.0,
    this.radius = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return goldSweepGradient.createShader(bounds);
      },
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: strokeWidth,
        backgroundColor: lightGrey,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

// A Card with gradient border
class GradientBorderCard extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double elevation;

  const GradientBorderCard({
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
          color: Colors.white,
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

// Apply gradient to any widget
class GradientWrapper extends StatelessWidget {
  final Widget child;
  final Gradient gradient;

  const GradientWrapper({
    super.key,
    required this.child,
    this.gradient = goldGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(bounds),
      child: child,
    );
  }
}
