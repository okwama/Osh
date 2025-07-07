import 'package:flutter/material.dart';
import 'package:woosh/utils/app_theme.dart';

enum BadgeStyle { normal, dot, pill }

class MenuTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;
  final String? subtitle;
  final double opacity;
  final Color? badgeColor;
  final bool showBadge;
  final BadgeStyle badgeStyle;

  const MenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.badgeCount,
    this.subtitle,
    this.opacity = 1.0,
    this.badgeColor,
    this.showBadge = true,
    this.badgeStyle = BadgeStyle.normal,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Card(
        elevation: 0.5,
        margin: const EdgeInsets.all(2),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => goldGradient.createShader(bounds),
                  child: Icon(
                    icon,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (badgeCount != null && showBadge) ...[
                  const SizedBox(height: 4),
                  _buildBadge(),
                ],
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    switch (badgeStyle) {
      case BadgeStyle.dot:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: badgeColor ?? Colors.red,
            shape: BoxShape.circle,
          ),
        );
      case BadgeStyle.pill:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor ?? Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badgeCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case BadgeStyle.normal:
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor ?? Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
  }
}
