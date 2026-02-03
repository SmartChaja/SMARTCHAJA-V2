// File: lib/features/chargenow_devices/view_model/charge_now_devices_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import '../../api_exception/chargenow_api_exception.dart';
import '../model/charge_now_device_params.dart';
import '../model/charge_now_device_list_response.dart';
import '../service/charge_now_service.dart';

// ... (ChargeNowDeviceStatus enum and ChargeNowDevicesState class remain the same) ...
enum ChargeNowDeviceStatus { initial, fetchingLocation, loading, success, empty, error }

class ChargeNowDevicesState {
  final ChargeNowDeviceStatus status;
  final List<DeviceListItem> devices;
  final String? errorMsg;
  final Position? lastUsedPosition;

  ChargeNowDevicesState({
    required this.status,
    this.devices = const [],
    this.errorMsg,
    this.lastUsedPosition,
  });

  ChargeNowDevicesState copyWith({
    ChargeNowDeviceStatus? status,
    List<DeviceListItem>? devices,
    String? errorMsg,
    Position? lastUsedPosition,
    bool clearError = false,
    bool clearDevices = false,
  }) {
    return ChargeNowDevicesState(
      status: status ?? this.status,
      devices: clearDevices ? [] : devices ?? this.devices,
      errorMsg: clearError ? null : errorMsg ?? this.errorMsg,
      lastUsedPosition: lastUsedPosition ?? this.lastUsedPosition,
    );
  }
}

class ChargeNowDevicesViewModel extends StateNotifier<ChargeNowDevicesState> {
  final ChargeNowService _service;

  ChargeNowDevicesViewModel(this._service)
      : super(ChargeNowDevicesState(status: ChargeNowDeviceStatus.initial));

  /// Get current location if available, returns null if location is disabled or denied
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled. Using default location.');
        return null; // Allow app to continue without location
      }

      // Check permission status
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission (but don't fail if denied)
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permissions are denied. Using default location.');
          return null; // Allow app to continue without location
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permissions are permanently denied. Using default location.');
        return null; // Allow app to continue without location
      }

      late LocationSettings locationSettings;
      const accuracy = LocationAccuracy.high;

      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: accuracy,
          distanceFilter: 10,
          intervalDuration: const Duration(seconds: 1),
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        locationSettings = AppleSettings(
          accuracy: accuracy,
          activityType: ActivityType.other,
          distanceFilter: 10,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: accuracy,
          distanceFilter: 10,
        );
      }
      
      print("✅ Requesting current position with settings: Accuracy ${locationSettings.accuracy}");
      return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    } catch (e) {
      print('⚠️ Error getting location: $e. Using default location.');
      return null; // Gracefully handle any location errors
    }
  }

  // fetchDevicesNearCurrentLocation and resetState methods remain the same
  Future<void> fetchDevicesNearCurrentLocation({
    CoordType coordType = CoordType.wgs84,
    String zoomLevel = "4",
    bool showPrice = true,
    bool forceRefresh = false,
  }) async {
    if ((state.status == ChargeNowDeviceStatus.loading || state.status == ChargeNowDeviceStatus.fetchingLocation) && !forceRefresh) return;
    
    state = state.copyWith(clearError: true);

    try {
      state = state.copyWith(status: ChargeNowDeviceStatus.fetchingLocation);
      
      // Try to get current location, but allow null (location disabled/denied)
      final Position? position = await _getCurrentLocation();
      
      // Use provided position or fallback to default location (Dar es Salaam - charging hub)
      final double latitude = position?.latitude ?? -6.8; // Dar es Salaam
      final double longitude = position?.longitude ?? 39.3; // Dar es Salaam
      
      state = state.copyWith(
        status: ChargeNowDeviceStatus.loading, 
        lastUsedPosition: position,
      );

      final params = ChargeNowDeviceParams(
        coordType: coordType,
        zoomLevel: zoomLevel,
        lat: latitude.toString(),
        lng: longitude.toString(),
        showPrice: showPrice,
      );

      final response = await _service.getDeviceList(params);
      if (response.code == 0) {
        if (response.list.isEmpty) {
          state = state.copyWith(status: ChargeNowDeviceStatus.empty, devices: [], clearError: true);
        } else {
          state = state.copyWith(status: ChargeNowDeviceStatus.success, devices: response.list, clearError: true);
        }
      } else {
        state = state.copyWith(status: ChargeNowDeviceStatus.error, errorMsg: response.msg, clearDevices: true);
      }
    } on ChargeNowApiException catch (e) {
      state = state.copyWith(status: ChargeNowDeviceStatus.error, errorMsg: e.message, clearDevices: true);
    } on Exception catch (e) {
      state = state.copyWith(status: ChargeNowDeviceStatus.error, errorMsg: e.toString().replaceFirst("Exception: ", ""), clearDevices: true);
    }
  }

  void resetState(){
      state = ChargeNowDevicesState(status: ChargeNowDeviceStatus.initial);
  }
}


// | Zoom Level | Geo Coverage Radius (Approx.)             |
// | ---------- | ----------------------------------------- |
// | 1          | 2500 km (very broad)                      |
// | 2          | 630 km                                    |
// | 3          | 78 km                                     |
// | 4          | 30 km                                     |
// | 5          | 2.4 km                                    |
// | 6          | 610 m                                     |
// | 7          | 76 m                                      |
// | 8          | 19 m (very tight, street-level precision) |
