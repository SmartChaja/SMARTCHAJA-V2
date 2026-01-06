// import 'package:flutter/material.dart';
// import 'package:flutter_localization/flutter_localization.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:smart_chaja/features/chargenow_devices/battery_monitor/battery_monitor_service.dart';
// import 'package:smart_chaja/localization/app_locale.dart';
// import 'dart:math' as math;

// // Provider for accessing ChargingPopupManager
// final chargingPopupManagerProvider = Provider<ChargingPopupManager>((ref) {
//   return ChargingPopupManager();
// });

// class ChargingPopupManager {
//   OverlayEntry? _overlayEntry;
//   BuildContext? _context;

//   void setContext(BuildContext context) {
//     _context = context;
//   }

//   void showChargingPopup() {
//     // Prevent showing multiple popups
//     if (_context == null || _overlayEntry != null) return;

//     _overlayEntry = OverlayEntry(
//       builder: (context) => ChargingPopup(
//         onClose: hideChargingPopup,
//       ),
//     );

//     // Use the stored context to insert the overlay
//     Overlay.of(_context!).insert(_overlayEntry!);
//   }

//   void hideChargingPopup() {
//     _overlayEntry?.remove();
//     _overlayEntry = null;
//   }
// }

// class ChargingPopup extends StatefulWidget {
//   final VoidCallback onClose;

//   const ChargingPopup({super.key, required this.onClose});

//   @override
//   State<ChargingPopup> createState() => _ChargingPopupState();
// }

// class _ChargingPopupState extends State<ChargingPopup> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _pulseAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeOutCubic,
//     ));

//     _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _controller,
//         curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
//       ),
//     );

//     _controller.forward();
//     _controller.repeat(reverse: true, period: const Duration(seconds: 2));
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer(
//       builder: (context, ref, child) {
//         final batteryService = BatteryMonitorService();
//         return FutureBuilder<Map<String, dynamic>>(
//           future: batteryService.getBatteryInfo(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData || snapshot.data!.isEmpty) {
//               // Show a loading or empty state briefly to avoid errors
//               return const SizedBox.shrink();
//             }

//             final batteryInfo = snapshot.data!;
//             final batteryLevel = batteryInfo['level'] as int? ?? 0;
//             final stats = batteryInfo['statistics'] as Map<String, dynamic>? ?? {};
//             final chargingRate = stats['currentChargingRate'] as double? ?? 0.0;
//             final estimatedChargingTime = Duration(minutes: stats['estimatedChargingTime'] as int? ?? 0);
            
//             final timestamps = batteryInfo['timestamps'] as Map<String, dynamic>? ?? {};
//             final chargingStartTimeStr = timestamps['chargingStartTime'] as String?;
//             final sessionDuration = chargingStartTimeStr != null
//                 ? DateTime.now().difference(DateTime.parse(chargingStartTimeStr))
//                 : Duration.zero;

//             return Material(
//               color: Colors.transparent,
//               child: Stack(
//                 children: [
//                   GestureDetector(
//                     onTap: widget.onClose,
//                     child: Container(
//                       color: Colors.black.withOpacity(0.4),
//                     ),
//                   ),
//                   SlideTransition(
//                     position: _slideAnimation,
//                     child: Align(
//                       alignment: Alignment.bottomCenter,
//                       child: Container(
//                         margin: const EdgeInsets.all(16),
//                         padding: const EdgeInsets.all(24),
//                         decoration: BoxDecoration(
//                           color: Theme.of(context).colorScheme.surface,
//                           borderRadius: BorderRadius.circular(16),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.2),
//                               blurRadius: 10,
//                               offset: const Offset(0, -2),
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   AppLocale.chargingStarted.getString(context),
//                                   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                                         color: Theme.of(context).colorScheme.primary,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(Icons.close),
//                                   onPressed: widget.onClose,
//                                   color: Theme.of(context).colorScheme.onSurface,
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             Center(
//                               child: CustomPaint(
//                                 painter: ChargingArcPainter(
//                                   progress: batteryLevel / 100,
//                                   pulse: _pulseAnimation.value,
//                                   primaryColor: Theme.of(context).colorScheme.primary,
//                                 ),
//                                 child: SizedBox(
//                                   width: 120,
//                                   height: 120,
//                                   child: Center(
//                                     child: ScaleTransition(
//                                       scale: _pulseAnimation,
//                                       child: Icon(
//                                         Icons.battery_charging_full,
//                                         size: 60,
//                                         color: Theme.of(context).colorScheme.primary,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 24),
//                             _buildStatRow(
//                               context,
//                               icon: Icons.battery_std,
//                               label: AppLocale.batteryLevel.getString(context),
//                               value: '$batteryLevel%',
//                             ),
//                             const SizedBox(height: 12),
//                             _buildStatRow(
//                               context,
//                               icon: Icons.speed,
//                               label: AppLocale.chargingRate.getString(context),
//                               value: '${chargingRate.toStringAsFixed(1)}%/h',
//                             ),
//                             const SizedBox(height: 12),
//                             _buildStatRow(
//                               context,
//                               icon: Icons.timer,
//                               label: AppLocale.estimatedTime.getString(context),
//                               value: _formatDuration(estimatedChargingTime),
//                             ),
//                             const SizedBox(height: 12),
//                             _buildStatRow(
//                               context,
//                               icon: Icons.history,
//                               label: AppLocale.sessionDuration.getString(context),
//                               value: _formatDuration(sessionDuration),
//                             ),
//                             const SizedBox(height: 24),
//                             SizedBox(
//                               width: double.infinity,
//                               child: ElevatedButton(
//                                 onPressed: () {
//                                   Navigator.of(context).pushNamed('/wallet');
//                                   widget.onClose();
//                                 },
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Theme.of(context).colorScheme.primary,
//                                   foregroundColor: Theme.of(context).colorScheme.onPrimary,
//                                 ),
//                                 child: Text(AppLocale.viewWallet.getString(context)),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildStatRow(BuildContext context, {required IconData icon, required String label, required String value}) {
//     return Row(
//       children: [
//         Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
//         const SizedBox(width: 8),
//         Text(
//           '$label: ',
//           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//         ),
//         Text(
//           value,
//           style: Theme.of(context).textTheme.bodyMedium,
//         ),
//       ],
//     );
//   }

//   String _formatDuration(Duration duration) {
//     if (duration.inMinutes < 1) return "Calculating...";
//     final hours = duration.inHours;
//     final minutes = duration.inMinutes % 60;
//     return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
//   }
// }

// class ChargingArcPainter extends CustomPainter {
//   final double progress;
//   final double pulse;
//   final Color primaryColor;

//   ChargingArcPainter({
//     required this.progress,
//     required this.pulse,
//     required this.primaryColor,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = size.width / 2;
//     final strokeWidth = 8.0 * pulse;

//     final bgPaint = Paint()
//       ..color = primaryColor.withOpacity(0.2)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;
//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       -math.pi / 2,
//       2 * math.pi,
//       false,
//       bgPaint,
//     );

//     final progressPaint = Paint()
//       ..color = primaryColor
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;
//     canvas.drawArc(
//       Rect.fromCircle(center: center, radius: radius),
//       -math.pi / 2,
//       2 * math.pi * progress,
//       false,
//       progressPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant ChargingArcPainter oldDelegate) {
//     return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
//   }
// }