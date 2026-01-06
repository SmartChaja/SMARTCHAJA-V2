
import 'package:smart_chaja/features/chargenow_devices/device_list/model/charge_now_device_list_response.dart';


class CachedData {
  final List<DeviceListItem> devices;
  final DateTime timestamp;

  CachedData(this.devices, this.timestamp);
}

class DeviceCache {
  static final Map<String, CachedData> _cache = {};
  static const Duration cacheExpiry = Duration(minutes: 5);

  static void cacheDevices(String key, List<DeviceListItem> devices) {
    _cache[key] = CachedData(devices, DateTime.now());
  }

  static List<DeviceListItem>? getCachedDevices(String key) {
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.timestamp) < cacheExpiry) {
      return cached.devices;
    }
    _cache.remove(key);
    return null;
  }

  static void clearExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) => now.difference(value.timestamp) > cacheExpiry);
  }
}