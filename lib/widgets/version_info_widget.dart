// import 'package:flutter/material.dart';
// import 'package:woosh/services/core/version_check_service.dart';

// class VersionInfoWidget extends StatefulWidget {
//   const VersionInfoWidget({super.key});

//   @override
//   State<VersionInfoWidget> createState() => _VersionInfoWidgetState();
// }

// class _VersionInfoWidgetState extends State<VersionInfoWidget>
//     with SingleTickerProviderStateMixin {
//   Map<String, String> _appInfo = {};
//   bool _isLoading = false;
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _pulseAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _loadAppInfo();

//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 200),
//       vsync: this,
//     );

//     _scaleAnimation = Tween<double>(
//       begin: 1.0,
//       end: 0.95,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));

//     _pulseAnimation = Tween<double>(
//       begin: 1.0,
//       end: 1.05,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.elasticOut,
//     ));
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadAppInfo() async {
//     final info = await VersionCheckService().getAppInfo();
//     setState(() {
//       _appInfo = info;
//     });
//   }

//   Future<void> _openAppStore() async {
//     if (_isLoading) return;

//     setState(() {
//       _isLoading = true;
//     });

//     _animationController.forward().then((_) {
//       _animationController.reverse();
//     });

//     try {
//       await VersionCheckService().launchStore();
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: AnimatedBuilder(
//         animation: _scaleAnimation,
//         builder: (context, child) {
//           return Transform.scale(
//             scale: _scaleAnimation.value,
//             child: GestureDetector(
//               onTap: _openAppStore,
//               onTapDown: (_) => _animationController.forward(),
//               onTapUp: (_) => _animationController.reverse(),
//               onTapCancel: () => _animationController.reverse(),
//               child: Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: _isLoading
//                         ? [
//                             Colors.grey.shade400.withOpacity(0.6),
//                             Colors.grey.shade500.withOpacity(0.6),
//                           ]
//                         : [
//                             theme.primaryColor.withOpacity(0.6),
//                             theme.primaryColor
//                                 .withBlue(
//                                   (theme.primaryColor.blue * 0.8).round(),
//                                 )
//                                 .withOpacity(0.6),
//                           ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(24),
//                   boxShadow: [
//                     BoxShadow(
//                       color: (_isLoading ? Colors.grey : theme.primaryColor)
//                           .withOpacity(0.15),
//                       blurRadius: 8,
//                       offset: const Offset(0, 4),
//                       spreadRadius: 0,
//                     ),
//                     BoxShadow(
//                       color: Colors.white.withOpacity(isDark ? 0.05 : 0.25),
//                       blurRadius: 1,
//                       offset: const Offset(0, 1),
//                       spreadRadius: 0,
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Version section
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                           color: Colors.white.withOpacity(0.15),
//                           width: 1,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.tag,
//                             size: 12,
//                             color: Colors.white.withOpacity(0.6),
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             'v${_appInfo['version'] ?? '1.0.1'}',
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white.withOpacity(0.7),
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(width: 12),

//                     // Divider
//                     Container(
//                       width: 1,
//                       height: 16,
//                       color: Colors.white.withOpacity(0.15),
//                     ),

//                     const SizedBox(width: 12),

//                     // Store section
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         if (_isLoading)
//                           SizedBox(
//                             width: 14,
//                             height: 14,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 Colors.white.withOpacity(0.6),
//                               ),
//                             ),
//                           )
//                         else
//                           Icon(
//                             Icons.store_rounded,
//                             size: 16,
//                             color: Colors.white.withOpacity(0.6),
//                           ),
//                         const SizedBox(width: 6),
//                         Text(
//                           _isLoading ? 'Opening...' : 'Check for updates',
//                           style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white.withOpacity(0.7),
//                             letterSpacing: 0.3,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
