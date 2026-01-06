import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/model/charge_now_device_list_response.dart';

class OfflineMapManager {
  static SharedPreferences? _prefs;
  static const Duration offlineCacheExpiry = Duration(minutes: 10);

  static Future<void> cacheMapData(String region, List<DeviceListItem> devices) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final jsonData = jsonEncode(devices.map((d) {
        try {
          return d.toJson();
        } catch (e) {
          print('Error serializing device: $e');
          return null;
        }
      }).where((d) => d != null).toList());
      await _prefs!.setString('map_cache_$region', jsonData);
      await _prefs!.setInt('map_cache_time_$region', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching map data for region $region: $e');
    }
  }

  static Future<List<DeviceListItem>?> getCachedMapData(String region) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final jsonData = _prefs!.getString('map_cache_$region');
      final timestamp = _prefs!.getInt('map_cache_time_$region') ?? 0;

      if (jsonData != null && _isCacheValid(timestamp)) {
        final List<dynamic> decoded = jsonDecode(jsonData);
        final devices = decoded.map((json) {
          try {
            return DeviceListItem.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('Error deserializing device: $e');
            return null;
          }
        }).where((d) => d != null).cast<DeviceListItem>().toList();
        return devices.isNotEmpty ? devices : null;
      }
    } catch (e) {
      print('Error loading cached map data for region $region: $e');
    }
    return null;
  }

  static bool _isCacheValid(int timestamp) {
    return DateTime.now().millisecondsSinceEpoch - timestamp < offlineCacheExpiry.inMilliseconds;
  }
}