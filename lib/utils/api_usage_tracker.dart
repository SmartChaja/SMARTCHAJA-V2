import 'dart:math' as math;

class ApiUsageTracker {
  static int _dailyRequests = 0;
  static DateTime _lastReset = DateTime.now();
  static const int dailyLimit = 1000;

  static void trackRequest() {
    if (_shouldResetCounter()) {
      _dailyRequests = 0;
      _lastReset = DateTime.now();
    }
    _dailyRequests++;

    if (_dailyRequests > (dailyLimit * 0.8)) {
      print('Warning: Approaching API limit. Used: $_dailyRequests/$dailyLimit');
    }
  }

  static bool _shouldResetCounter() {
    final now = DateTime.now();
    return now.year > _lastReset.year || now.month > _lastReset.month || now.day > _lastReset.day;
  }

  static int get remainingRequests => math.max(0, dailyLimit - _dailyRequests);
}