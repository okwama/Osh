import 'package:flutter/material.dart';

class ClientSearchIndicator extends StatefulWidget {
  final String searchQuery;

  const ClientSearchIndicator({
    super.key,
    required this.searchQuery,
  });

  @override
  State<ClientSearchIndicator> createState() => _ClientSearchIndicatorState();
}

class _ClientSearchIndicatorState extends State<ClientSearchIndicator> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated search icon with pulsing effect
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              );
            },
            onEnd: () {
              // Restart animation
              if (mounted) {
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 24),
          // Searching text with animated dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Searching',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              _buildAnimatedDots(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Looking for "${widget.searchQuery}"',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Progress indicator
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return TweenAnimationBuilder<int>(
      tween: Tween(begin: 0, end: 3),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Text(
          '.' * value,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
