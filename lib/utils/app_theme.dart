import 'package:flutter/material.dart';

// App Colors
const Color blackColor = Color.fromARGB(255, 0, 0, 0);
const Color accentGrey = Color(0xFF666666);
const Color lightGrey = Color.fromARGB(255, 236, 235, 227);
const Color appBackground = Color(0xFFF4EBD0);

// Gold Gradient Colors
const Color goldStart = Color(0xFFAE8625);
const Color goldMiddle1 = Color(0xFFF7EF8A);
const Color goldMiddle2 = Color(0xFFD2AC47);
const Color goldEnd = Color(0xFFEDC967);

// Gold Gradient - Linear (for backgrounds, buttons, etc.)
const LinearGradient goldGradient = LinearGradient(
  colors: [goldStart, goldMiddle1, goldMiddle2, goldEnd],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Radial Gold Gradient (for circular elements)
const RadialGradient goldRadialGradient = RadialGradient(
  colors: [goldMiddle1, goldMiddle2, goldStart],
  radius: 1.0,
);

// Sweep Gold Gradient (for circular progress indicators)
const SweepGradient goldSweepGradient = SweepGradient(
  colors: [goldStart, goldMiddle1, goldMiddle2, goldEnd, goldStart],
);

// Helper class for creating gradient decorations
class GradientDecoration {
  // Box decoration with gold gradient
  static BoxDecoration goldBox({double borderRadius = 8.0, BoxBorder? border}) {
    return BoxDecoration(
      gradient: goldGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
    );
  }

  // Circular decoration with gold gradient
  static BoxDecoration goldCircular({BoxBorder? border}) {
    return BoxDecoration(
      gradient: goldRadialGradient,
      shape: BoxShape.circle,
      border: border,
    );
  }
}

// Custom paint classes for gradient-enabled widgets
class GoldGradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Paint paint = Paint()..shader = goldGradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Gradient text widget
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => goldGradient.createShader(bounds),
      child: Text(
        text,
        style: style?.copyWith(color: Colors.white) ??
            const TextStyle(color: Colors.white),
        textAlign: textAlign,
      ),
    );
  }
}

// Gradient Button
class GoldGradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GoldGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 8.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GradientDecoration.goldBox(borderRadius: borderRadius),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}

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
