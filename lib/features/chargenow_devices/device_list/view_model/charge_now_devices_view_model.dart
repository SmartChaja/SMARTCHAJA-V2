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

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them in your device settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied. Please grant permission to proceed.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in app settings.');
    } 

    late LocationSettings locationSettings;
    const accuracy = LocationAccuracy.high; // Define desired accuracy

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: 10, // Optional: meters
        intervalDuration: const Duration(seconds: 1), // More relevant for streams/foreground
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: accuracy,
        activityType: ActivityType.other, // Specify activity type
        distanceFilter: 10, // Optional: meters
     
        // showBackgroundLocationIndicator: false, // Optional: if running in background
      );
    } else {
      // Generic settings for web or other platforms
      locationSettings = const LocationSettings(
        accuracy: accuracy,
        distanceFilter: 10, // Optional
        // timeLimit: Duration(seconds: 10), // Optional: to timeout the request
      );
    }
    
    print("Requesting current position with settings: Accuracy ${locationSettings.accuracy}");
    return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
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
      final Position position = await _getCurrentLocation();
      state = state.copyWith(status: ChargeNowDeviceStatus.loading, lastUsedPosition: position);

      final params = ChargeNowDeviceParams(
        coordType: coordType,
        zoomLevel: zoomLevel,
        lat: position.latitude.toString(),
        lng: position.longitude.toString(),
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
