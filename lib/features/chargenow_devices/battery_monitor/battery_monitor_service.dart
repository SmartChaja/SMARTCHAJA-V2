// import 'dart:async';
// import 'dart:io';
// import 'dart:math';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:battery_plus/battery_plus.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:flutter/material.dart';

// class BatteryMonitorService {
//   static final BatteryMonitorService _instance = BatteryMonitorService._internal();
//   factory BatteryMonitorService() => _instance;
//   BatteryMonitorService._internal();

//   final Battery _battery = Battery();
//   final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
//   StreamSubscription<BatteryState>? _batteryStateSubscription;
//   Timer? _batteryCheckTimer;
//   Timer? _periodicReminderTimer;
//   Timer? _advancedStatsTimer;
  
//   // Navigation context
//   static BuildContext? _navigationContext;
  
//   // Configuration
//   int _lowBatteryThreshold = 20;
//   int _criticalBatteryThreshold = 10;
//   bool _isMonitoring = false;
//   bool _enablePeriodicReminders = true;
//   bool _enableAdvancedNotifications = true;
//   DateTime? _lastNotificationTime;
//   DateTime? _lastCriticalNotificationTime;
//   DateTime? _chargingStartTime;
//   DateTime? _dischargingStartTime;
//   DateTime? _screenOnTime;
//   DateTime? _screenOffTime;
  
//   // Advanced battery statistics
//   int _previousBatteryLevel = 0;
//   BatteryState _previousBatteryState = BatteryState.unknown;
//   double _currentChargingRate = 0.0; // %/hour
//   double _peakChargingRate = 0.0; // %/hour
//   double _averageChargingRate = 0.0; // %/hour
//   double _dischargingRate = 0.0; // %/hour
//   Duration _estimatedTimeLeft = Duration.zero;
//   Duration _estimatedChargingTime = Duration.zero;
//   Duration _totalChargingTime = Duration.zero;
//   Duration _totalScreenOnTime = Duration.zero;
//   Duration _totalScreenOffTime = Duration.zero;
//   Duration _deepSleepTime = Duration.zero;
//   Duration _activeTime = Duration.zero;
//   int _chargingCycles = 0;
//   int _chargingSessionsToday = 0;
//   int _chargingStartLevel = 0; // Tracks starting battery level
//   double _batteryHealth = 100.0;
//   double _batteryTemperature = 25.0; // Estimated °C
//   double _energyConsumed = 0.0; // Estimated mAh
//   ChargingPhase _currentPhase = ChargingPhase.initial;
//   ChargingEfficiency _efficiency = ChargingEfficiency.optimal;
//   List<ChargingDataPoint> _chargingHistory = [];
  
//   // Notification scheduling
//   static const int _lowBatteryNotificationId = 1;
//   static const int _criticalBatteryNotificationId = 2;
//   static const int _periodicReminderNotificationId = 3;
//   static const int _chargingCompleteNotificationId = 4;
//   static const int _advancedStatsNotificationId = 5;
//   static const int _chargingProgressNotificationId = 6;
  
//   // Getters and setters
//   int get lowBatteryThreshold => _lowBatteryThreshold;
//   int get criticalBatteryThreshold => _criticalBatteryThreshold;
//   bool get isMonitoring => _isMonitoring;
//   bool get enablePeriodicReminders => _enablePeriodicReminders;
//   bool get enableAdvancedNotifications => _enableAdvancedNotifications;
//   double get chargingRate => _currentChargingRate;
//   double get dischargingRate => _dischargingRate;
//   Duration get estimatedTimeLeft => _estimatedTimeLeft;
//   Duration get estimatedChargingTime => _estimatedChargingTime;
//   double get batteryHealth => _batteryHealth;
  
//   // Set navigation context
//   static void setNavigationContext(BuildContext context) {
//     _navigationContext = context;
//   }
  
//   void setLowBatteryThreshold(int threshold) {
//     _lowBatteryThreshold = threshold;
//   }
  
//   void setCriticalBatteryThreshold(int threshold) {
//     _criticalBatteryThreshold = threshold;
//   }

//   void setPeriodicReminders(bool enabled) {
//     _enablePeriodicReminders = enabled;
//     if (!enabled) {
//       _cancelPeriodicReminders();
//     }
//   }

//   void setAdvancedNotifications(bool enabled) {
//     _enableAdvancedNotifications = enabled;
//     if (!enabled) {
//       _notificationsPlugin.cancel(_advancedStatsNotificationId);
//       _notificationsPlugin.cancel(_chargingProgressNotificationId);
//     }
//   }

//   /// Initialize the battery monitor service
//   Future<bool> initialize() async {
//     try {
//       // Initialize timezone data for scheduling
//       tz.initializeTimeZones();
      
//       // Initialize local notifications
//       await _initializeNotifications();
      
//       // Request all necessary permissions
//       await _requestAllPermissions();
      
//       // Initialize battery stats
//       _previousBatteryLevel = await _battery.batteryLevel;
//       _previousBatteryState = await _battery.batteryState;
      
//       debugPrint('✅ Enhanced Battery Monitor Service initialized');
//       return true;
//     } catch (e) {
//       debugPrint('❌ Error initializing Battery Monitor Service: $e');
//       return false;
//     }
//   }

//   /// Initialize local notifications with enhanced settings
//   Future<void> _initializeNotifications() async {
//     const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
//     const iosInitializationSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       requestCriticalPermission: true,
//     );

//     const initializationSettings = InitializationSettings(
//       android: androidInitializationSettings,
//       iOS: iosInitializationSettings,
//     );

//     await _notificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: _onNotificationTapped,
//     );

//     // Create notification channels for Android
//     if (Platform.isAndroid) {
//       await _createNotificationChannels();
//     }
//   }

//   /// Create notification channels for different types of alerts
//   Future<void> _createNotificationChannels() async {
//     final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
//     if (androidPlugin != null) {
//       // Low battery channel
//       await androidPlugin.createNotificationChannel(
//         const AndroidNotificationChannel(
//           'battery_low',
//           'Low Battery Alerts',
//           description: 'Smart notifications when your battery needs attention',
//           importance: Importance.high,
//           playSound: true,
//           enableVibration: true,
//         ),
//       );

//       // Critical battery channel
//       await androidPlugin.createNotificationChannel(
//         const AndroidNotificationChannel(
//           'battery_critical',
//           'Critical Battery Alerts',
//           description: 'Urgent alerts when your battery is critically low',
//           importance: Importance.max,
//           playSound: true,
//           enableVibration: true,
//           enableLights: true,
//         ),
//       );

//       // Advanced stats channel
//       await androidPlugin.createNotificationChannel(
//         const AndroidNotificationChannel(
//           'battery_stats',
//           'Battery Statistics',
//           description: 'Detailed battery usage and charging information',
//           importance: Importance.low,
//           playSound: false,
//           enableVibration: false,
//           showBadge: false,
//         ),
//       );

//       // Charging progress channel
//       await androidPlugin.createNotificationChannel(
//         const AndroidNotificationChannel(
//           'charging_progress',
//           'Charging Progress',
//           description: 'Real-time charging progress and detailed statistics',
//           importance: Importance.defaultImportance,
//           playSound: false,
//           enableVibration: false,
//           showBadge: false,
//         ),
//       );

//       // Periodic reminders channel
//       await androidPlugin.createNotificationChannel(
//         const AndroidNotificationChannel(
//           'battery_reminders',
//           'Smart Chaja Reminders',
//           description: 'Helpful reminders about Smart Chaja power banks',
//           importance: Importance.defaultImportance,
//           playSound: false,
//           enableVibration: false,
//         ),
//       );

//       // Charging status channel
//       await androidPlugin.createNotificationChannel(
//         const AndroidNotificationChannel(
//           'charging_status',
//           'Charging Status',
//           description: 'Updates about your device charging status',
//           importance: Importance.defaultImportance,
//           playSound: true,
//           enableVibration: false,
//         ),
//       );
//     }
//   }

//   /// Handle notification tap with enhanced navigation
//   void _onNotificationTapped(NotificationResponse response) {
//     debugPrint('Notification tapped: ${response.payload}');
    
//     if (_navigationContext == null) {
//       debugPrint('⚠️ Navigation context not set');
//       return;
//     }
    
//     switch (response.payload) {
//       case 'low_battery':
//       case 'critical_battery':
//         _navigateToMap();
//         break;
//       case 'periodic_reminder':
//         _navigateToHome();
//         break;
//       case 'charging_complete':
//       case 'charging_progress':
//         _navigateToWallet();
//         break;
//       case 'advanced_stats':
//       case 'view_details':
//       case 'view_graph':
//         _navigateToProfile();
//         break;
//       case 'find_powerbank':
//         _navigateToMap();
//         break;
//       case 'scan_qr':
//         _navigateToScan();
//         break;
//       case 'stop_monitoring':
//         stopMonitoring();
//         break;
//     }
//   }

//   void _navigateToMap() {
//     if (_navigationContext != null) {
//       Navigator.of(_navigationContext!).pushNamed('/map');
//       debugPrint('📍 Navigating to map screen');
//     }
//   }

//   void _navigateToHome() {
//     if (_navigationContext != null) {
//       Navigator.of(_navigationContext!).pushNamedAndRemoveUntil('/', (route) => false);
//       debugPrint('🏠 Navigating to home screen');
//     }
//   }

//   void _navigateToWallet() {
//     if (_navigationContext != null) {
//       Navigator.of(_navigationContext!).pushNamed('/wallet');
//       debugPrint('💳 Navigating to wallet screen');
//     }
//   }

//   void _navigateToProfile() {
//     if (_navigationContext != null) {
//       Navigator.of(_navigationContext!).pushNamed('/profile');
//       debugPrint('👤 Navigating to profile screen');
//     }
//   }

//   void _navigateToScan() {
//     if (_navigationContext != null) {
//       Navigator.of(_navigationContext!).pushNamed('/scan');
//       debugPrint('📱 Navigating to scan screen');
//     }
//   }

//   /// Request all necessary permissions
//   Future<void> _requestAllPermissions() async {
//     if (Platform.isAndroid) {
//       // Request notification permission
//       final notificationStatus = await Permission.notification.status;
//       if (!notificationStatus.isGranted) {
//         await Permission.notification.request();
//       }

//       // Request exact alarm permission for Android 12+
//       final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
//       if (androidPlugin != null) {
//         try {
//           final exactAlarmPermission = await androidPlugin.requestExactAlarmsPermission();
//           debugPrint('Exact alarm permission: $exactAlarmPermission');
//         } catch (e) {
//           debugPrint('⚠️ Could not request exact alarm permission: $e');
//         }
//       }

//       // Request system alert window permission for critical alerts
//       final systemAlertStatus = await Permission.systemAlertWindow.status;
//       if (!systemAlertStatus.isGranted) {
//         await Permission.systemAlertWindow.request();
//       }
//     }
//   }

//   /// Start monitoring battery level with enhanced features
//   Future<void> startMonitoring() async {
//     if (_isMonitoring) {
//       debugPrint('⚠️ Battery monitoring is already active');
//       return;
//     }

//     try {
//       _isMonitoring = true;
      
//       // Initialize battery stats
//       _previousBatteryLevel = await _battery.batteryLevel;
//       _previousBatteryState = await _battery.batteryState;
      
//       if (_previousBatteryState == BatteryState.charging) {
//         await _startChargingSession(_previousBatteryLevel);
//       }

//       // Check battery level immediately
//       await _checkBatteryLevel();
      
//       // Set up periodic battery checks (every 2 minutes for responsive monitoring)
//       _batteryCheckTimer = Timer.periodic(
//         const Duration(minutes: 2),
//         (timer) => _checkBatteryLevel(),
//       );
      
//       // Set up advanced stats updates (every 15 seconds for charging data)
//       if (_enableAdvancedNotifications) {
//         _advancedStatsTimer = Timer.periodic(
//           const Duration(seconds: 15),
//           (timer) => _updateAdvancedStats(),
//         );
//       }
      
//       // Set up periodic reminders (every 3 hours when battery is okay)
//       if (_enablePeriodicReminders) {
//         _startPeriodicReminders();
//       }
      
//       // Listen to battery state changes
//       _batteryStateSubscription = _battery.onBatteryStateChanged.listen((BatteryState state) {
//         _handleBatteryStateChange(state);
//       });
      
//       debugPrint('✅ Enhanced battery monitoring started');
//     } catch (e) {
//       debugPrint('❌ Error starting battery monitoring: $e');
//       _isMonitoring = false;
//     }
//   }

//   /// Start a new charging session
//   Future<void> _startChargingSession(int currentLevel) async {
//     _chargingStartTime = DateTime.now();
//     _chargingStartLevel = currentLevel;
//     _chargingHistory.clear();
//     _currentPhase = _determineChargingPhase(currentLevel);
//     _chargingSessionsToday++;
//     _totalChargingTime = Duration.zero;
//     _currentChargingRate = 0.0;
//     _peakChargingRate = 0.0;
//     _averageChargingRate = 0.0;
//     _screenOffTime = DateTime.now(); // Reset for idle time tracking
    
//     debugPrint('🔌 Charging session started at $currentLevel%');
//     await _showChargingProgressNotification(currentLevel, true);
//   }

//   /// End charging session
//   Future<void> _endChargingSession() async {
//     if (_chargingStartTime != null) {
//       _totalChargingTime = DateTime.now().difference(_chargingStartTime!);
//       debugPrint('🔋 Charging session ended. Duration: ${_formatDuration(_totalChargingTime)}');
//     }
    
//     await _notificationsPlugin.cancel(_chargingProgressNotificationId);
//     _chargingStartTime = null;
//     _chargingStartLevel = 0;
//     _chargingHistory.clear();
//   }

//   /// Start periodic reminders about Smart Chaja services
//   void _startPeriodicReminders() {
//     _periodicReminderTimer = Timer.periodic(
//       const Duration(hours: 3),
//       (timer) => _sendPeriodicReminder(),
//     );
//   }

//   /// Stop monitoring battery level
//   void stopMonitoring() {
//     _isMonitoring = false;
//     _batteryCheckTimer?.cancel();
//     _batteryStateSubscription?.cancel();
//     _advancedStatsTimer?.cancel();
//     _cancelPeriodicReminders();
//     _notificationsPlugin.cancel(_chargingProgressNotificationId);
//     debugPrint('🛑 Battery monitoring stopped');
//   }

//   /// Cancel periodic reminders
//   void _cancelPeriodicReminders() {
//     _periodicReminderTimer?.cancel();
//     _notificationsPlugin.cancel(_periodicReminderNotificationId);
//   }

//   /// Enhanced battery level checking with advanced statistics
//   Future<void> _checkBatteryLevel() async {
//     try {
//       final batteryLevel = await _battery.batteryLevel;
//       final batteryState = await _battery.batteryState;
      
//       // Calculate charging/discharging rates
//       _calculateBatteryRates(batteryLevel, batteryState);
      
//       debugPrint('🔋 Battery: $batteryLevel%, State: $batteryState, Rate: ${_currentChargingRate.toStringAsFixed(1)}%/h');
      
//       // Handle different battery states
//       switch (batteryState) {
//         case BatteryState.charging:
//           await _handleChargingState(batteryLevel);
//           break;
//         case BatteryState.discharging:
//           await _handleDischargingState(batteryLevel);
//           break;
//         case BatteryState.full:
//           await _handleFullBattery();
//           break;
//         case BatteryState.unknown:
//         case BatteryState.connectedNotCharging:
//           // Continue monitoring
//           break;
//       }
      
//       // Update previous values
//       _previousBatteryLevel = batteryLevel;
//       _previousBatteryState = batteryState;
      
//     } catch (e) {
//       debugPrint('❌ Error checking battery level: $e');
//     }
//   }

//   /// Calculate charging and discharging rates
//   void _calculateBatteryRates(int currentLevel, BatteryState currentState) {
//     final now = DateTime.now();
    
//     if (_previousBatteryState != currentState) {
//       // State changed, reset timers
//       if (currentState == BatteryState.charging) {
//         _startChargingSession(currentLevel);
//       } else if (currentState == BatteryState.discharging) {
//         _dischargingStartTime = now;
//         _screenOffTime = now; // Reset for idle time tracking
//         _endChargingSession();
//       }
//     }
    
//     // Calculate rates based on level changes over time
//     if (_previousBatteryLevel != currentLevel && _previousBatteryLevel > 0) {
//       final levelDiff = currentLevel - _previousBatteryLevel;
//       final timeDiff = 2.0; // minutes between checks
      
//       if (currentState == BatteryState.charging && levelDiff > 0) {
//         _currentChargingRate = (levelDiff / timeDiff) * 60; // %/hour
//         _averageChargingRate = (_averageChargingRate + _currentChargingRate) / 2;
//         if (_currentChargingRate > _peakChargingRate) {
//           _peakChargingRate = _currentChargingRate;
//         }
//         _estimatedChargingTime = _calculateChargingTimeLeft(currentLevel, _currentChargingRate);
//         _currentPhase = _determineChargingPhase(currentLevel);
//         _efficiency = _determineChargingEfficiency();
//         _batteryTemperature = _estimateBatteryTemperature();
//         _energyConsumed = levelDiff * 30; // Assuming ~3000mAh battery
//         _chargingHistory.add(ChargingDataPoint(
//           timestamp: now,
//           batteryLevel: currentLevel,
//           chargingRate: _currentChargingRate,
//           temperature: _batteryTemperature,
//           phase: _currentPhase,
//         ));
//         if (_chargingHistory.length > 50) {
//           _chargingHistory.removeAt(0);
//         }
//       } else if (currentState == BatteryState.discharging && levelDiff < 0) {
//         _dischargingRate = (levelDiff.abs() / timeDiff) * 60; // %/hour
//         _estimatedTimeLeft = _calculateBatteryTimeLeft(currentLevel, _dischargingRate);
//       }
//     }
//   }

//   /// Calculate estimated charging time to full
//   Duration _calculateChargingTimeLeft(int currentLevel, double rate) {
//     if (rate <= 0) return Duration.zero;
//     final percentageLeft = 100 - currentLevel;
//     final hoursLeft = percentageLeft / rate;
//     return Duration(minutes: (hoursLeft * 60).round());
//   }

//   /// Calculate estimated battery time left
//   Duration _calculateBatteryTimeLeft(int currentLevel, double rate) {
//     if (rate <= 0) return Duration.zero;
//     final hoursLeft = currentLevel / rate;
//     return Duration(minutes: (hoursLeft * 60).round());
//   }

//   /// Update and show advanced battery statistics
//   Future<void> _updateAdvancedStats() async {
//     if (!_enableAdvancedNotifications) return;
    
//     try {
//       final batteryLevel = await _battery.batteryLevel;
//       final batteryState = await _battery.batteryState;
      
//       await _showAdvancedStatsNotification(batteryLevel, batteryState);
      
//       if (batteryState == BatteryState.charging) {
//         await _showChargingProgressNotification(batteryLevel, false);
//       }
      
//     } catch (e) {
//       debugPrint('❌ Error updating advanced stats: $e');
//     }
//   }

//   /// Show advanced battery statistics notification
//   Future<void> _showAdvancedStatsNotification(int batteryLevel, BatteryState batteryState) async {
//     String stateText = _getBatteryStateDescription(batteryState);
//     String timeText = _getTimeEstimateText(batteryState, batteryLevel);
//     String healthText = 'Health: ${_batteryHealth.toStringAsFixed(0)}%';
    
//     final androidDetails = AndroidNotificationDetails(
//       'battery_stats',
//       'Battery Statistics',
//       channelDescription: 'Detailed battery information',
//       importance: Importance.low,
//       priority: Priority.low,
//       ongoing: true,
//       autoCancel: false,
//       showWhen: false,
//       icon: _getBatteryIcon(batteryLevel, batteryState),
//       color: _getBatteryColor(batteryLevel, batteryState),
//       largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
//     );

//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: false,
//       presentBadge: false,
//       presentSound: false,
//     );

//     var notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     await _notificationsPlugin.show(
//       _advancedStatsNotificationId,
//       '🔋 $batteryLevel% • $stateText',
//       '$timeText • $healthText',
//       notificationDetails,
//       payload: 'advanced_stats',
//     );
//   }

//   /// Show enhanced charging progress notification
//   Future<void> _showChargingProgressNotification(int batteryLevel, bool isNewSession) async {
//     if (batteryLevel >= 100) return;
    
//     String progressText = _getChargingProgressText(batteryLevel);
//     String estimateText = _getChargingEstimateText();
//     String idleText = _getIdleTimeText();
//     String healthText = 'Health: ${_batteryHealth.toStringAsFixed(0)}%';
//     String cyclesText = 'Cycles: $_chargingCycles';
//     String sessionText = _getChargingSessionInfo();
//     String efficiencyText = _getEfficiencyInfo();
//     String phaseText = _getPhaseInfo();
//     String temperatureText = _getTemperatureInfo();
//     String energyText = _getEnergyConsumedText();
//     String sessionsText = 'Sessions Today: $_chargingSessionsToday';
    
//     final androidDetails = AndroidNotificationDetails(
//       'charging_progress',
//       'Charging Progress',
//       channelDescription: 'Real-time charging progress and detailed statistics',
//       importance: Importance.defaultImportance,
//       priority: Priority.defaultPriority,
//       ongoing: true,
//       autoCancel: false,
//       showWhen: true,
//       when: DateTime.now().millisecondsSinceEpoch,
//       showProgress: true,
//       maxProgress: 100,
//       progress: batteryLevel,
//       indeterminate: false,
//       icon: _getChargingIcon(batteryLevel),
//       color: _getChargingColor(batteryLevel),
//       styleInformation: BigTextStyleInformation(
//         '$progressText • $estimateText\n$sessionText\n$idleText\n$efficiencyText • $phaseText\n$temperatureText • $energyText\n$healthText • $cyclesText • $sessionsText',
//         contentTitle: '⚡ Charging $batteryLevel% - Smart Chaja',
//         summaryText: 'Detailed Charging Stats',
//       ),
//       actions: <AndroidNotificationAction>[
//         const AndroidNotificationAction(
//           'view_details',
//           '📊 View Details',
//           titleColor: Color(0xFF2196F3),
//         ),
//         const AndroidNotificationAction(
//           'view_graph',
//           '📈 View Graph',
//           titleColor: Color(0xFF4CAF50),
//         ),
//         const AndroidNotificationAction(
//           'stop_monitoring',
//           '⏹️ Stop Monitoring',
//           titleColor: Color(0xFF757575),
//         ),
//       ],
//     );

//     var iosDetails = DarwinNotificationDetails(
//       presentAlert: false,
//       presentBadge: false,
//       presentSound: isNewSession,
//       threadIdentifier: 'charging_progress',
//     );

//     var notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     await _notificationsPlugin.show(
//       _chargingProgressNotificationId,
//       '⚡ Charging $batteryLevel%',
//       '$progressText • $estimateText',
//       notificationDetails,
//       payload: 'charging_progress',
//     );

//     debugPrint('⚡ Charging progress notification updated: $batteryLevel%');
//   }

//   /// Get battery state description
//   String _getBatteryStateDescription(BatteryState state) {
//     switch (state) {
//       case BatteryState.charging:
//         return 'Charging';
//       case BatteryState.discharging:
//         return 'Active';
//       case BatteryState.full:
//         return 'Full';
//       case BatteryState.connectedNotCharging:
//         return 'Connected';
//       case BatteryState.unknown:
//         return 'Unknown';
//     }
//   }

//   /// Get time estimate text
//   String _getTimeEstimateText(BatteryState state, int level) {
//     switch (state) {
//       case BatteryState.charging:
//         if (_estimatedChargingTime.inMinutes > 0) {
//           return 'Full in ${_formatDuration(_estimatedChargingTime)}';
//         }
//         return 'Calculating time...';
//       case BatteryState.discharging:
//         if (_estimatedTimeLeft.inMinutes > 0) {
//           return '${_formatDuration(_estimatedTimeLeft)} left';
//         }
//         return 'Calculating time...';
//       case BatteryState.full:
//         return 'Battery is full';
//       default:
//         return 'Ready to use';
//     }
//   }

//   /// Get charging progress text
//   String _getChargingProgressText(int level) {
//     if (_currentChargingRate > 0) {
//       return 'Rate: ${_currentChargingRate.toStringAsFixed(1)}%/h (Peak: ${_peakChargingRate.toStringAsFixed(1)}%/h)';
//     }
//     return 'Charging...';
//   }

//   /// Get charging estimate text
//   String _getChargingEstimateText() {
//     if (_estimatedChargingTime.inMinutes > 0) {
//       return 'Full in ${_formatDuration(_estimatedChargingTime)}';
//     }
//     return 'Calculating...';
//   }

//   /// Get idle time text
//   String _getIdleTimeText() {
//     if (_screenOffTime != null && _chargingStartTime != null) {
//       final idleDuration = DateTime.now().difference(_screenOffTime!);
//       return 'Idle: ${_formatDuration(idleDuration)}';
//     }
//     return 'Idle: Unknown';
//   }

//   /// Get charging session info
//   String _getChargingSessionInfo() {
//     if (_chargingStartTime == null) return 'Session: Not started';
//     final duration = DateTime.now().difference(_chargingStartTime!);
//     return 'Session: ${_formatDuration(duration)} (Started at $_chargingStartLevel%)';
//   }

//   /// Get charging efficiency info
//   String _getEfficiencyInfo() {
//     String efficiencyEmoji = _efficiency == ChargingEfficiency.optimal ? '🟢' :
//                             _efficiency == ChargingEfficiency.good ? '🟡' : '🔴';
//     return '$efficiencyEmoji Efficiency: ${_efficiency.toString().split('.').last.toUpperCase()}';
//   }

//   /// Get charging phase info
//   String _getPhaseInfo() {
//     String phaseEmoji = _currentPhase == ChargingPhase.fast ? '⚡' :
//                        _currentPhase == ChargingPhase.normal ? '🔋' :
//                        _currentPhase == ChargingPhase.trickle ? '🐌' : '🔄';
//     return '$phaseEmoji Phase: ${_currentPhase.toString().split('.').last.toUpperCase()}';
//   }

//   /// Get temperature info
//   String _getTemperatureInfo() {
//     String tempStatus = _batteryTemperature < 30 ? 'COOL' :
//                        _batteryTemperature < 35 ? 'NORMAL' :
//                        _batteryTemperature < 40 ? 'WARM' : 'HOT';
//     return 'Temp: ${_batteryTemperature.toStringAsFixed(1)}°C ($tempStatus)';
//   }

//   /// Get energy consumed text
//   String _getEnergyConsumedText() {
//     return 'Energy: ${_energyConsumed.toStringAsFixed(0)}mAh';
//   }

//   /// Format duration to readable string
//   String _formatDuration(Duration duration) {
//     if (duration.inHours > 0) {
//       final hours = duration.inHours;
//       final minutes = duration.inMinutes % 60;
//       return '${hours}h ${minutes}m';
//     } else {
//       return '${duration.inMinutes}m';
//     }
//   }

//   /// Get appropriate battery icon
//   String _getBatteryIcon(int level, BatteryState state) {
//     if (state == BatteryState.charging) {
//       return _getChargingIcon(level);
//     } else if (level <= 10) {
//       return '@drawable/battery_critical';
//     } else if (level <= 20) {
//       return '@drawable/battery_low';
//     } else if (level >= 100) {
//       return '@drawable/battery_full';
//     } else {
//       return '@drawable/battery_good';
//     }
//   }

//   /// Get appropriate charging icon
//   String _getChargingIcon(int batteryLevel) {
//     debugPrint('🔌 Using fallback charging icon for level: $batteryLevel%');
//     return '@drawable/battery_charging';
//   }

//   /// Get appropriate battery color
//   Color _getBatteryColor(int level, BatteryState state) {
//     if (state == BatteryState.charging) {
//       return _getChargingColor(level);
//     } else if (level <= 10) {
//       return const Color(0xFFD32F2F); // Red
//     } else if (level <= 20) {
//       return const Color(0xFFFF9800); // Orange
//     } else {
//       return const Color(0xFF2196F3); // Blue
//     }
//   }

//   /// Get appropriate charging color
//   Color _getChargingColor(int batteryLevel) {
//     if (batteryLevel >= 80) return const Color(0xFF4CAF50); // Green
//     if (batteryLevel >= 60) return const Color(0xFF8BC34A); // Light Green
//     if (batteryLevel >= 40) return const Color(0xFFFFEB3B); // Yellow
//     if (batteryLevel >= 20) return const Color(0xFFFF9800); // Orange
//     return const Color(0xFFFF5722); // Deep Orange
//   }

//   /// Determine charging phase
//   ChargingPhase _determineChargingPhase(int batteryLevel) {
//     if (batteryLevel < 80) return ChargingPhase.fast;
//     if (batteryLevel < 95) return ChargingPhase.normal;
//     return ChargingPhase.trickle;
//   }

//   /// Determine charging efficiency
//   ChargingEfficiency _determineChargingEfficiency() {
//     if (_currentChargingRate > 20) return ChargingEfficiency.optimal;
//     if (_currentChargingRate > 10) return ChargingEfficiency.good;
//     return ChargingEfficiency.poor;
//   }

//   /// Estimate battery temperature
//   double _estimateBatteryTemperature() {
//     final baseTemp = 25.0;
//     final rateMultiplier = _currentChargingRate * 0.3;
//     final timeMultiplier = _chargingStartTime != null 
//         ? DateTime.now().difference(_chargingStartTime!).inMinutes * 0.05 
//         : 0.0;
//     return min(45.0, baseTemp + rateMultiplier + timeMultiplier);
//   }

//   /// Handle charging state
//   Future<void> _handleChargingState(int batteryLevel) async {
//     // Cancel low battery notifications when charging
//     await _notificationsPlugin.cancel(_lowBatteryNotificationId);
//     await _notificationsPlugin.cancel(_criticalBatteryNotificationId);
    
//     // If battery reaches 100%, send charging complete notification
//     if (batteryLevel >= 100) {
//       await _sendChargingCompleteNotification();
//       _chargingCycles++;
//       _updateBatteryHealth();
//     }
//   }

//   /// Handle discharging state
//   Future<void> _handleDischargingState(int batteryLevel) async {
//     // Cancel charging notifications when discharging
//     await _notificationsPlugin.cancel(_chargingProgressNotificationId);
    
//     if (batteryLevel <= _criticalBatteryThreshold) {
//       await _sendCriticalBatteryNotification(batteryLevel);
//     } else if (batteryLevel <= _lowBatteryThreshold) {
//       await _sendLowBatteryNotification(batteryLevel);
//     }
//   }

//   /// Handle full battery
//   Future<void> _handleFullBattery() async {
//     await _sendChargingCompleteNotification();
//   }

//   /// Handle battery state changes with enhanced logic
//   void _handleBatteryStateChange(BatteryState state) {
//     debugPrint('🔋 Battery state changed: $state');
    
//     switch (state) {
//       case BatteryState.charging:
//         _chargingStartTime = DateTime.now();
//         _screenOffTime = DateTime.now(); // Reset for idle time tracking
//         debugPrint('🔌 Device started charging');
//         break;
//       case BatteryState.discharging:
//         _dischargingStartTime = DateTime.now();
//         _screenOffTime = DateTime.now(); // Reset for idle time tracking
//         debugPrint('🔋 Device started discharging');
//         _checkBatteryLevel();
//         break;
//       case BatteryState.full:
//         debugPrint('✅ Battery is full');
//         _handleFullBattery();
//         break;
//       case BatteryState.unknown:
//         debugPrint('❓ Battery state unknown');
//         break;
//       case BatteryState.connectedNotCharging:
//         debugPrint('🔌 Connected but not charging');
//         break;
//     }
//   }

//   /// Send enhanced low battery notification
//   Future<void> _sendLowBatteryNotification(int batteryLevel) async {
//     // Prevent spam notifications (only send once per hour)
//     if (_lastNotificationTime != null && 
//         DateTime.now().difference(_lastNotificationTime!) < const Duration(hours: 1)) {
//       return;
//     }

//     String timeLeftText = '';
//     if (_estimatedTimeLeft.inMinutes > 0) {
//       timeLeftText = ' • ${_formatDuration(_estimatedTimeLeft)} left';
//     }

//     const androidDetails = AndroidNotificationDetails(
//       'battery_low',
//       'Low Battery Alerts',
//       channelDescription: 'Smart notifications when your battery needs attention',
//       importance: Importance.high,
//       priority: Priority.high,
//       icon: '@drawable/battery_low',
//       color: Color(0xFFFF9800),
//       playSound: true,
//       enableVibration: true,
//       actions: <AndroidNotificationAction>[
//         AndroidNotificationAction(
//           'find_powerbank',
//           '🔍 Find Power Bank',
//           titleColor: Color(0xFF2196F3),
//         ),
//         AndroidNotificationAction(
//           'scan_qr',
//           '📱 Quick Scan',
//           titleColor: Color(0xFF4CAF50),
//         ),
//       ],
//     );

//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//       categoryIdentifier: 'battery_low',
//     );

//     const notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     await _notificationsPlugin.show(
//       _lowBatteryNotificationId,
//       '🔋 Battery Running Low',
//       'Your battery is at $batteryLevel%$timeLeftText. Time to find a Smart Chaja power bank!',
//       notificationDetails,
//       payload: 'low_battery',
//     );

//     _lastNotificationTime = DateTime.now();
//     debugPrint('📱 Low battery notification sent');
//   }

//   /// Send enhanced critical battery notification
//   Future<void> _sendCriticalBatteryNotification(int batteryLevel) async {
//     // Allow critical notifications more frequently (every 20 minutes)
//     if (_lastCriticalNotificationTime != null && 
//         DateTime.now().difference(_lastCriticalNotificationTime!) < const Duration(minutes: 20)) {
//       return;
//     }

//     String urgentText = '';
//     if (_estimatedTimeLeft.inMinutes > 0 && _estimatedTimeLeft.inMinutes < 30) {
//       urgentText = ' Your device may shut down in ${_formatDuration(_estimatedTimeLeft)}!';
//     }

//     const androidDetails = AndroidNotificationDetails(
//       'battery_critical',
//       'Critical Battery Alerts',
//       channelDescription: 'Urgent alerts when your battery is critically low',
//       importance: Importance.max,
//       priority: Priority.max,
//       icon: '@drawable/battery_critical',
//       color: Color(0xFFD32F2F),
//       playSound: true,
//       enableVibration: true,
//       enableLights: true,
//       fullScreenIntent: true,
//       actions: <AndroidNotificationAction>[
//         AndroidNotificationAction(
//           'find_powerbank',
//           '🚨 Find Now!',
//           titleColor: Color(0xFFD32F2F),
//         ),
//         AndroidNotificationAction(
//           'scan_qr',
//           '⚡ Emergency Scan',
//           titleColor: Color(0xFFFF9800),
//         ),
//       ],
//     );

//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//       interruptionLevel: InterruptionLevel.critical,
//       categoryIdentifier: 'battery_critical',
//     );

//     const notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     await _notificationsPlugin.show(
//       _criticalBatteryNotificationId,
//       '⚠️ Critical Battery Alert!',
//       'Only $batteryLevel% remaining!$urgentText Rent a Smart Chaja power bank immediately!',
//       notificationDetails,
//       payload: 'critical_battery',
//     );

//     _lastCriticalNotificationTime = DateTime.now();
//     debugPrint('🚨 Critical battery notification sent');
//   }

//   /// Send charging complete notification
//   Future<void> _sendChargingCompleteNotification() async {
//     Duration chargingDuration = Duration.zero;
//     if (_chargingStartTime != null) {
//       chargingDuration = DateTime.now().difference(_chargingStartTime!);
//     }

//     String durationText = '';
//     if (chargingDuration.inMinutes > 0) {
//       durationText = ' Charged from $_chargingStartLevel% in ${_formatDuration(chargingDuration)}.';
//     }

//     String statsText = 'Peak Rate: ${_peakChargingRate.toStringAsFixed(1)}%/h | Energy: ${_energyConsumed.toStringAsFixed(0)}mAh | Efficiency: ${_efficiency.toString().split('.').last.toUpperCase()}';

//     var androidDetails = AndroidNotificationDetails(
//       'charging_status',
//       'Charging Status',
//       channelDescription: 'Updates about your device charging status',
//       importance: Importance.defaultImportance,
//       priority: Priority.defaultPriority,
//       icon: '@drawable/battery_full',
//       color: const Color(0xFF4CAF50),
//       playSound: true,
//       styleInformation: BigTextStyleInformation(
//         'Charged to 100%!$durationText\n$statsText\nThanks for using Smart Chaja responsibly.',
//         contentTitle: '✅ Charging Complete!',
//         summaryText: 'Session Summary',
//       ),
//       actions: <AndroidNotificationAction>[
//         const AndroidNotificationAction(
//           'view_details',
//           '📊 View Details',
//           titleColor: Color(0xFF2196F3),
//         ),
//         const AndroidNotificationAction(
//           'view_graph',
//           '📈 View Graph',
//           titleColor: Color(0xFF4CAF50),
//         ),
//       ],
//     );

//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: false,
//       presentSound: true,
//     );

//     var notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     // Cancel charging progress notification
//     await _notificationsPlugin.cancel(_chargingProgressNotificationId);

//     await _notificationsPlugin.show(
//       _chargingCompleteNotificationId,
//       '✅ Charging Complete!',
//       'Charged to 100%!$durationText',
//       notificationDetails,
//       payload: 'charging_complete',
//     );

//     debugPrint('🔋 Charging complete notification sent');
//   }

//   /// Send periodic reminder about Smart Chaja services
//   Future<void> _sendPeriodicReminder() async {
//     if (!_enablePeriodicReminders) return;

//     // Only send reminders when battery is okay (above low threshold)
//     final batteryLevel = await _battery.batteryLevel;
//     if (batteryLevel <= _lowBatteryThreshold) return;

//     const androidDetails = AndroidNotificationDetails(
//       'battery_reminders',
//       'Smart Chaja Reminders',
//       channelDescription: 'Helpful reminders about Smart Chaja power banks',
//       importance: Importance.defaultImportance,
//       priority: Priority.defaultPriority,
//       icon: '@mipmap/ic_launcher',
//       color: Color(0xFF2196F3),
//       actions: <AndroidNotificationAction>[
//         AndroidNotificationAction(
//           'find_powerbank',
//           '🗺️ View Map',
//           titleColor: Color(0xFF4CAF50),
//         ),
//         AndroidNotificationAction(
//           'dismiss',
//           'Got it',
//         ),
//       ],
//     );

//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: false,
//       presentSound: false,
//     );

//     const notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     final messages = [
//       {
//         'title': '🌟 Smart Chaja is Here for You!',
//         'body': 'Power banks available 24/7 across the city. Your battery is good now, but we\'re ready when you need us!'
//       },
//       {
//         'title': '⚡ Never Run Out of Power Again',
//         'body': 'Smart Chaja\'s rental network has you covered. Affordable rates, convenient locations!'
//       },
//       {
//         'title': '🔋 Planning a Long Day?',
//         'body': 'Check Smart Chaja locations on your map. Stay powered up wherever you go!'
//       },
//       {
//         'title': '📱 Smart Charging Solutions',
//         'body': 'Premium power banks with fast charging. Perfect for busy professionals and students!'
//       },
//       {
//         'title': '🎯 Smart Chaja Tip',
//         'body': 'Rent a power bank before your battery hits 20%. Prevention is better than emergency!'
//       },
//     ];

//     final randomMessage = messages[Random().nextInt(messages.length)];

//     await _notificationsPlugin.show(
//       _periodicReminderNotificationId,
//       randomMessage['title']!,
//       randomMessage['body']!,
//       notificationDetails,
//       payload: 'periodic_reminder',
//     );

//     debugPrint('📱 Periodic reminder sent');
//   }

//   /// Schedule a notification for later
//   Future<void> scheduleNotification({
//     required int id,
//     required String title,
//     required String body,
//     required DateTime scheduledTime,
//     String? payload,
//   }) async {
//     await _notificationsPlugin.zonedSchedule(
//       id,
//       title,
//       body,
//       tz.TZDateTime.from(scheduledTime, tz.local),
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'battery_reminders',
//           'Smart Chaja Reminders',
//           channelDescription: 'Scheduled reminders',
//           importance: Importance.defaultImportance,
//           priority: Priority.defaultPriority,
//           icon: '@mipmap/ic_launcher',
//         ),
//         iOS: DarwinNotificationDetails(
//           presentAlert: true,
//           presentBadge: true,
//           presentSound: true,
//         ),
//       ),
//       payload: payload,
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//     );
//   }

//   /// Schedule smart battery reminder based on usage patterns
//   Future<void> scheduleSmartReminder() async {
//     final batteryLevel = await _battery.batteryLevel;
    
//     if (batteryLevel > 50) {
//       // Schedule reminder for when battery might reach 30%
//       final estimatedTime = _calculateTimeToLevel(30);
//       if (estimatedTime.inMinutes > 60) {
//         final reminderTime = DateTime.now().add(estimatedTime - const Duration(minutes: 30));
//         await scheduleNotification(
//           id: 100,
//           title: '🔋 Battery Reminder',
//           body: 'Your battery will be low soon. Consider finding a Smart Chaja power bank nearby!',
//           scheduledTime: reminderTime,
//           payload: 'smart_reminder',
//         );
//       }
//     }
//   }

//   /// Calculate time to reach specific battery level
//   Duration _calculateTimeToLevel(int targetLevel) {
//     final currentLevel = _previousBatteryLevel;
//     if (_dischargingRate <= 0 || currentLevel <= targetLevel) {
//       return Duration.zero;
//     }
    
//     final levelDiff = currentLevel - targetLevel;
//     final hoursToTarget = levelDiff / _dischargingRate;
//     return Duration(minutes: (hoursToTarget * 60).round());
//   }

//   /// Get comprehensive battery info with advanced statistics
//   Future<Map<String, dynamic>> getBatteryInfo() async {
//     try {
//       final batteryLevel = await _battery.batteryLevel;
//       final batteryState = await _battery.batteryState;
      
//       return {
//         'level': batteryLevel,
//         'state': batteryState.toString(),
//         'stateDescription': _getBatteryStateDescription(batteryState),
//         'isCharging': batteryState == BatteryState.charging,
//         'isFull': batteryState == BatteryState.full,
//         'isLow': batteryLevel <= _lowBatteryThreshold,
//         'isCritical': batteryLevel <= _criticalBatteryThreshold,
//         'isMonitoring': _isMonitoring,
//         'periodicRemindersEnabled': _enablePeriodicReminders,
//         'advancedNotificationsEnabled': _enableAdvancedNotifications,
//         'thresholds': {
//           'low': _lowBatteryThreshold,
//           'critical': _criticalBatteryThreshold,
//         },
//         'statistics': {
//           'currentChargingRate': _currentChargingRate,
//           'peakChargingRate': _peakChargingRate,
//           'averageChargingRate': _averageChargingRate,
//           'dischargingRate': _dischargingRate,
//           'estimatedTimeLeft': _estimatedTimeLeft.inMinutes,
//           'estimatedChargingTime': _estimatedChargingTime.inMinutes,
//           'totalChargingTime': _totalChargingTime.inMinutes,
//           'batteryHealth': _batteryHealth,
//           'chargingCycles': _chargingCycles,
//           'chargingSessionsToday': _chargingSessionsToday,
//           'chargingStartLevel': _chargingStartLevel,
//           'batteryTemperature': _batteryTemperature,
//           'energyConsumed': _energyConsumed,
//           'chargingPhase': _currentPhase.toString(),
//           'chargingEfficiency': _efficiency.toString(),
//           'totalScreenOnTime': _totalScreenOnTime.inMinutes,
//           'totalScreenOffTime': _totalScreenOffTime.inMinutes,
//           'deepSleepTime': _deepSleepTime.inMinutes,
//           'activeTime': _activeTime.inMinutes,
//         },
//         'timestamps': {
//           'chargingStartTime': _chargingStartTime?.toIso8601String(),
//           'dischargingStartTime': _dischargingStartTime?.toIso8601String(),
//           'lastNotificationTime': _lastNotificationTime?.toIso8601String(),
//           'lastCriticalNotificationTime': _lastCriticalNotificationTime?.toIso8601String(),
//           'screenOnTime': _screenOnTime?.toIso8601String(),
//           'screenOffTime': _screenOffTime?.toIso8601String(),
//         },
//         'chargingHistory': _chargingHistory.map((point) => point.toJson()).toList(),
//       };
//     } catch (e) {
//       debugPrint('❌ Error getting battery info: $e');
//       return {};
//     }
//   }

//   /// Get battery usage recommendations
//   List<String> getBatteryRecommendations() {
//     final recommendations = <String>[];
    
//     if (_dischargingRate > 15) {
//       recommendations.add('⚡ Your battery is draining fast. Consider reducing screen brightness or closing background apps.');
//     }
    
//     if (_currentChargingRate < 10 && _currentChargingRate > 0) {
//       recommendations.add('🔌 Charging slowly detected. Use original charger or check cable connection.');
//     }
    
//     if (_chargingCycles > 500) {
//       recommendations.add('🔋 High charging cycles detected. Consider replacing battery for optimal performance.');
//     }
    
//     if (_batteryHealth < 85) {
//       recommendations.add('⚠️ Battery health is declining. Smart Chaja power banks can help extend your device life.');
//     }
    
//     if (_batteryTemperature > 35) {
//       recommendations.add('💡 Device is warm. Consider removing case while charging.');
//     }
    
//     if (recommendations.isEmpty) {
//       recommendations.add('✅ Your battery is performing well! Smart Chaja is here when you need extra power.');
//     }
    
//     return recommendations;
//   }

//   /// Send a comprehensive test notification
//   Future<void> sendTestNotification() async {
//     const androidDetails = AndroidNotificationDetails(
//       'battery_low',
//       'Low Battery Alerts',
//       channelDescription: 'Test notification with all features',
//       importance: Importance.high,
//       priority: Priority.high,
//       icon: '@mipmap/ic_launcher',
//       color: Color(0xFF2196F3),
//       playSound: true,
//       enableVibration: true,
//       actions: <AndroidNotificationAction>[
//         AndroidNotificationAction(
//           'find_powerbank',
//           '🔍 Find Power Bank',
//           titleColor: Color(0xFF4CAF50),
//         ),
//         AndroidNotificationAction(
//           'view_details',
//           '📊 View Stats',
//           titleColor: Color(0xFF2196F3),
//         ),
//         AndroidNotificationAction(
//           'scan_qr',
//           '📱 Quick Scan',
//           titleColor: Color(0xFFFF9800),
//         ),
//       ],
//     );

//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );

//     const notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     final batteryInfo = await getBatteryInfo();
//     final level = batteryInfo['level'] ?? 0;
//     final state = batteryInfo['stateDescription'] ?? 'Unknown';

//     await _notificationsPlugin.show(
//       999,
//       '🧪 Smart Chaja Test Alert',
//       'Battery: $level% • $state • All systems working perfectly! Tap to explore options.',
//       notificationDetails,
//       payload: 'test',
//     );

//     debugPrint('🧪 Comprehensive test notification sent');
//   }

//   /// Clear all notifications
//   Future<void> clearAllNotifications() async {
//     await _notificationsPlugin.cancelAll();
//     debugPrint('🧹 All notifications cleared');
//   }

//   /// Reset battery statistics
//   void resetStatistics() {
//     _currentChargingRate = 0.0;
//     _peakChargingRate = 0.0;
//     _averageChargingRate = 0.0;
//     _dischargingRate = 0.0;
//     _estimatedTimeLeft = Duration.zero;
//     _estimatedChargingTime = Duration.zero;
//     _totalChargingTime = Duration.zero;
//     _chargingCycles = 0;
//     _chargingSessionsToday = 0;
//     _chargingStartLevel = 0;
//     _batteryHealth = 100.0;
//     _batteryTemperature = 25.0;
//     _energyConsumed = 0.0;
//     _totalScreenOnTime = Duration.zero;
//     _totalScreenOffTime = Duration.zero;
//     _deepSleepTime = Duration.zero;
//     _activeTime = Duration.zero;
//     _chargingHistory.clear();
    
//     debugPrint('📊 Battery statistics reset');
//   }

//   /// Update battery health estimation
//   void _updateBatteryHealth() {
//     // Simple health estimation based on charging cycles and temperature
//     if (_chargingCycles > 0) {
//       final cycleImpact = _chargingCycles * 0.05;
//       final tempImpact = _batteryTemperature > 35 ? (_batteryTemperature - 35) * 0.1 : 0.0;
//       _batteryHealth = max(70.0, 100.0 - cycleImpact - tempImpact);
//     }
//   }

//   /// Get user-friendly battery status message
//   String getBatteryStatusMessage() {
//     final level = _previousBatteryLevel;
//     final state = _previousBatteryState;
    
//     if (state == BatteryState.charging) {
//       if (level >= 95) {
//         return '🎉 Almost fully charged! You\'re ready for anything.';
//       } else if (level >= 80) {
//         return '⚡ Charging well! Your device will be ready soon.';
//       } else {
//         return '🔌 Charging in progress. Smart Chaja keeps you powered!';
//       }
//     } else if (state == BatteryState.full) {
//       return '✅ Fully charged and ready to go! Have a great day.';
//     } else if (level <= 5) {
//       return '🚨 Critical! Your device needs power immediately. Find Smart Chaja now!';
//     } else if (level <= 15) {
//       return '⚠️ Very low battery. Time to rent a Smart Chaja power bank!';
//     } else if (level <= 30) {
//       return '🔋 Getting low. Consider grabbing a Smart Chaja power bank nearby.';
//     } else if (level <= 50) {
//       return '📱 Moderate battery. Perfect time to plan your next charge!';
//     } else {
//       return '😊 Battery looking good! Smart Chaja is here when you need us.';
//     }
//   }

//   /// Dispose resources
//   void dispose() {
//     stopMonitoring();
//     _batteryCheckTimer?.cancel();
//     _batteryStateSubscription?.cancel();
//     _periodicReminderTimer?.cancel();
//     _advancedStatsTimer?.cancel();
//     clearAllNotifications();
//   }
// }

// // Data classes for charging information
// class ChargingDataPoint {
//   final DateTime timestamp;
//   final int batteryLevel;
//   final double chargingRate;
//   final double temperature;
//   final ChargingPhase phase;

//   ChargingDataPoint({
//     required this.timestamp,
//     required this.batteryLevel,
//     required this.chargingRate,
//     required this.temperature,
//     required this.phase,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'timestamp': timestamp.toIso8601String(),
//       'batteryLevel': batteryLevel,
//       'chargingRate': chargingRate,
//       'temperature': temperature,
//       'phase': phase.toString(),
//     };
//   }
// }

// enum ChargingPhase { initial, fast, normal, trickle }
// enum ChargingEfficiency { optimal, good, poor }