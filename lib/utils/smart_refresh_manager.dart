import 'package:geolocator/geolocator.dart' as geo;

class SmartRefreshManager {
  static DateTime? _lastRefresh;
  static geo.Position? _lastPosition;
  static const Duration minRefreshInterval = Duration(minutes: 2);
  static const double minDistanceThreshold = 500.0;

  static bool shouldRefresh({bool forceRefresh = false, geo.Position? newPosition}) {
    if (forceRefresh) return true;

    if (_lastRefresh == null || DateTime.now().difference(_lastRefresh!) > minRefreshInterval) {
      return true;
    }

    if (newPosition != null && _lastPosition != null) {
      final distance = geo.Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      return distance > minDistanceThreshold;
    }

    return false;
  }

  static void markRefreshed({geo.Position? position}) {
    _lastRefresh = DateTime.now();
    if (position != null) {
      _lastPosition = position;
    }
  }
}