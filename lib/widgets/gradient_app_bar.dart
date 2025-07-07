import 'package:flutter/material.dart';
import 'package:woosh/utils/app_theme.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Widget? leading;
  final double elevation;
  final bool automaticallyImplyLeading;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    this.leading,
    this.elevation = 0,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: goldGradient,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                )
              ]
            : null,
      ),
      child: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        actions: actions,
        leading: leading,
        bottom: bottom,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

// A Gradient Flexible space factory for SliverAppBar
class GradientFlexibleSpaceBar extends StatelessWidget {
  final String title;
  final bool centerTitle;

  const GradientFlexibleSpaceBar({
    super.key,
    required this.title,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: goldGradient),
      child: FlexibleSpaceBar(
        centerTitle: centerTitle,
        title: Text(
          title,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: goldGradient,
          ),
        ),
      ),
    );
  }
}
