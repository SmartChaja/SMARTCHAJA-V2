import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:smart_chaja/app_constants/app_constants.dart';
import 'package:smart_chaja/features/chargenow_devices/widgets/custom_bottom_navigation_bar.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/model/charge_now_device_list_response.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/provider/charge_now_devices_provider.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/view/widgets/search.dart';
import 'package:smart_chaja/features/chargenow_devices/device_list/view_model/charge_now_devices_view_model.dart';
import 'package:smart_chaja/localization/app_locale.dart';
import 'package:smart_chaja/reusable_widgets/snack_bar.dart';
import 'package:smart_chaja/utils/cache_manager.dart';
import 'package:smart_chaja/utils/location_debouncer.dart';
import 'package:smart_chaja/utils/offline_map_manager.dart';
import 'dart:math' as math;
import 'widgets/device_details_sheet.dart';
import 'widgets/status_overlay.dart';

class ChargeNowDevicesScreen extends ConsumerStatefulWidget {
  const ChargeNowDevicesScreen({super.key});

  @override
  ConsumerState<ChargeNowDevicesScreen> createState() =>
      _ChargeNowDevicesScreenState();
}

class _ChargeNowDevicesScreenState
    extends ConsumerState<ChargeNowDevicesScreen> {
  final Completer<GoogleMapController> _mapControllerCompleter =
      Completer<GoogleMapController>();
  GoogleMapController? _googleMapController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const CameraPosition _kInitialCameraPosition = CameraPosition(
    target: LatLng(-6.8, 39.3), // Dar es Salaam - charging station hub
    zoom: 13.0,
  );

  Set<Marker> _markers = {};
  BitmapDescriptor? _stationMarkerIconOnline;
  BitmapDescriptor? _stationMarkerIconOffline;
  BitmapDescriptor? _myLocationMarkerIcon;

  bool _isMapReady = false;
  LatLngBounds? _currentViewport;
  bool _isUpdatingMarkers = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    DeviceCache.clearExpiredCache();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeMap();
      }
    });
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    LocationDebouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    LocationDebouncer.debounce(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
        final chargeNowState = ref.read(chargeNowDevicesViewModelProvider);
        _updateMarkers(chargeNowState.devices, chargeNowState.lastUsedPosition);
        if (_isMapReady) {
          _fitBounds(_filterDevicesBySearch(chargeNowState.devices));
        }
      }
    });
  }

  void _onSearchClear() {
    _searchController.clear();
  }

  Future<void> _initializeMap() async {
    final chargeNowNotifier =
        ref.read(chargeNowDevicesViewModelProvider.notifier);
    final region = _getCurrentRegionKey();
    final cachedDevices = await OfflineMapManager.getCachedMapData(region);

    if (cachedDevices != null && cachedDevices.isNotEmpty) {
      _updateMarkers(cachedDevices, null);
    }

    chargeNowNotifier.fetchDevicesNearCurrentLocation();
  }

  String _getCurrentRegionKey() {
    const camera = _kInitialCameraPosition;
    return '${camera.target.latitude.toStringAsFixed(1)}_${camera.target.longitude.toStringAsFixed(1)}';
  }

  Future<void> _loadCustomMarkers() async {
    try {
      _stationMarkerIconOnline = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(64, 64)),
          'assets/images/station_online_marker.png');
      _stationMarkerIconOffline = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(64, 64)),
          'assets/images/station_offline_marker.png');
      _myLocationMarkerIcon = await BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/images/my_location_marker.png');
      if (mounted) setState(() {});
    } catch (e) {
      print("Error loading custom markers: $e. Using default markers.");
    }
  }

  List<DeviceListItem> _filterDevicesBySearch(List<DeviceListItem> devices) {
    if (_searchQuery.isEmpty) return devices;
    return devices.where((device) {
      final shop = device.shop;
      if (shop == null) return false;
      final nameMatch = shop.shopName.toLowerCase().contains(_searchQuery);
      final addressMatch =
          shop.shopAddress.toLowerCase().contains(_searchQuery);
      return nameMatch || addressMatch;
    }).toList();
  }

  void _updateMarkers(
      List<DeviceListItem> devices, geo.Position? currentUserLocation) {
    if (_isUpdatingMarkers) return;
    _isUpdatingMarkers = true;

    try {
      final searchedDevices = _filterDevicesBySearch(devices);
      final visibleDevices = _currentViewport != null
          ? _filterDevicesInViewport(searchedDevices, _currentViewport!)
          : searchedDevices;
      _updateMarkersEfficiently(visibleDevices, currentUserLocation);
    } finally {
      _isUpdatingMarkers = false;
    }
  }

  List<DeviceListItem> _filterDevicesInViewport(
      List<DeviceListItem> devices, LatLngBounds viewport) {
    return devices.where((device) {
      final shop = device.shop;
      if (shop?.latitude.isEmpty ?? true) {
        return false;
      }
      try {
        final lat = double.parse(shop!.latitude);
        final lng = double.parse(shop.longitude);
        return lat >= viewport.southwest.latitude &&
            lat <= viewport.northeast.latitude &&
            lng >= viewport.southwest.longitude &&
            lng <= viewport.northeast.longitude;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  void _updateMarkersEfficiently(
      List<DeviceListItem> devices, geo.Position? currentUserLocation) {
    final Set<Marker> newMarkers = {};
    final existingIds = _markers.map((m) => m.markerId.value).toSet();
    final newIds = <String>{};

    for (final device in devices) {
      final shop = device.shop;
      if (shop != null &&
          shop.latitude.isNotEmpty &&
          shop.longitude.isNotEmpty) {
        try {
          final lat = double.parse(shop.latitude);
          final lng = double.parse(shop.longitude);
          final bool isOnline = device.cabinet?.infoStatus == "1";
          final markerId = shop.id;
          newIds.add(markerId);

          if (!existingIds.contains(markerId)) {
            newMarkers.add(
              Marker(
                markerId: MarkerId(markerId),
                position: LatLng(lat, lng),
                icon: isOnline
                    ? (_stationMarkerIconOnline ??
                        BitmapDescriptor.defaultMarker)
                    : (_stationMarkerIconOffline ??
                        BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueOrange)),
                infoWindow: InfoWindow(
                  title: shop.shopName,
                  snippet: "Available: ${device.cabinet?.freeNum ?? 'N/A'}",
                  onTap: () => showDeviceDetailsSheet(context, device),
                ),
                onTap: () => showDeviceDetailsSheet(context, device),
              ),
            );
          } else {
            final existingMarker =
                _markers.firstWhere((m) => m.markerId.value == markerId);
            newMarkers.add(existingMarker);
          }
        } catch (e) {
          print("Error creating marker for ${shop.shopName}: $e");
        }
      }
    }

    if (currentUserLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: LatLng(
              currentUserLocation.latitude, currentUserLocation.longitude),
          icon: _myLocationMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: "My Location"),
          zIndex: 1.0,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  Future<void> _animateToPosition(LatLng position, {double zoom = 14.0}) async {
    if (!_isMapReady || _googleMapController == null) return;
    try {
      await _googleMapController!.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ));
    } catch (e) {
      print("Error animating to position: $e");
      if (mounted) {
        TopSnackBar.show(
          context,
          AppLocale.failedToCenterMap.getString(context),
          iconData: Icons.error_outline_rounded,
          color: AppColors.errorColor,
        );
      }
    }
  }

  Future<void> _fitBounds(List<DeviceListItem> devices) async {
    if (devices.isEmpty || !_isMapReady || _googleMapController == null) return;

    if (devices.length == 1 && devices.first.shop != null) {
      final shop = devices.first.shop!;
      try {
        final lat = double.parse(shop.latitude);
        final lng = double.parse(shop.longitude);
        await _animateToPosition(LatLng(lat, lng), zoom: 15.0);
      } catch (_) {}
      return;
    }

    double? minLat, maxLat, minLng, maxLng;

    for (var device in devices) {
      final shop = device.shop;
      if (shop != null &&
          shop.latitude.isNotEmpty &&
          shop.longitude.isNotEmpty) {
        try {
          final lat = double.parse(shop.latitude);
          final lng = double.parse(shop.longitude);
          minLat = minLat == null ? lat : math.min(minLat, lat);
          maxLat = maxLat == null ? lat : math.max(maxLat, lat);
          minLng = minLng == null ? lng : math.min(minLng, lng);
          maxLng = maxLng == null ? lng : math.max(maxLng, lng);
        } catch (_) {
          print("Error parsing lat/lng for shop ${shop.shopName}");
        }
      }
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      if ((maxLat - minLat).abs() < 0.0001 &&
          (maxLng - minLng).abs() < 0.0001) {
        await _animateToPosition(LatLng(minLat, minLng), zoom: 15.0);
        return;
      }

      final southwest = LatLng(minLat, minLng);
      final northeast = LatLng(maxLat, maxLng);
      final bounds = LatLngBounds(southwest: southwest, northeast: northeast);

      Future.delayed(const Duration(milliseconds: 200), () async {
        if (mounted && _googleMapController != null) {
          try {
            await _googleMapController!
                .animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
          } catch (e) {
            print("Error animating camera to bounds: $e");
            await _animateToPosition(
              LatLng((minLat! + maxLat!) / 2, (minLng! + maxLng!) / 2),
              zoom: 10,
            );
          }
        }
      });
    } else if (devices.isNotEmpty && devices.first.shop != null) {
      final shop = devices.first.shop!;
      try {
        final lat = double.parse(shop.latitude);
        final lng = double.parse(shop.longitude);
        await _animateToPosition(LatLng(lat, lng), zoom: 13.0);
      } catch (_) {}
    }
  }

  void _onMapReady() {
    if (mounted) setState(() => _isMapReady = true);
    final chargeNowState = ref.read(chargeNowDevicesViewModelProvider);

    if (chargeNowState.devices.isNotEmpty) {
      _fitBounds(chargeNowState.devices);
    } else if (chargeNowState.lastUsedPosition != null) {
      _animateToPosition(
        LatLng(chargeNowState.lastUsedPosition!.latitude,
            chargeNowState.lastUsedPosition!.longitude),
        zoom: 13.0,
      );
    } else {
      _googleMapController
          ?.moveCamera(CameraUpdate.newCameraPosition(_kInitialCameraPosition));
    }
  }

  void _onCameraMove(CameraPosition position) {
    LocationDebouncer.debounce(() {
      final double offset = _getOffsetForZoom(position.zoom);
      _currentViewport = LatLngBounds(
        southwest: LatLng(position.target.latitude - offset,
            position.target.longitude - offset),
        northeast: LatLng(position.target.latitude + offset,
            position.target.longitude + offset),
      );
      final chargeNowState = ref.read(chargeNowDevicesViewModelProvider);
      _updateMarkers(chargeNowState.devices, chargeNowState.lastUsedPosition);
    });
  }

  double _getOffsetForZoom(double zoom) {
    if (zoom >= 15) return 0.01;
    if (zoom >= 12) return 0.05;
    if (zoom >= 8) return 0.2;
    return 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final chargeNowState = ref.watch(chargeNowDevicesViewModelProvider);
    final chargeNowNotifier =
        ref.read(chargeNowDevicesViewModelProvider.notifier);

    ref.listen<ChargeNowDevicesState>(chargeNowDevicesViewModelProvider,
        (prev, next) {
      if (next.status == ChargeNowDeviceStatus.error && next.errorMsg != null) {
        if (mounted) {
          TopSnackBar.show(
            context,
            next.errorMsg!.contains("network")
                ? AppLocale.networkError.getString(context)
                : next.errorMsg ??
                    AppLocale.failedToLoadStations.getString(context),
            iconData: Icons.error_outline_rounded,
            color: AppColors.errorColor,
          );
        }
      }

      // Check if state changes require map update or cache.
      // This listener will now also react to `initial` state after reset.
      bool shouldUpdateMap = false;
      if (prev?.status != next.status &&
          (next.status == ChargeNowDeviceStatus.success ||
              next.status == ChargeNowDeviceStatus.empty ||
              next.status ==
                  ChargeNowDeviceStatus
                      .fetchingLocation || // Added to ensure map reacts to fetching state
              next.status == ChargeNowDeviceStatus.loading)) {
        // Added for loading state
        shouldUpdateMap = true;
      } else if (next.status == ChargeNowDeviceStatus.success &&
          prev?.devices.length != next.devices.length) {
        shouldUpdateMap = true;
      }

      if (shouldUpdateMap) {
        _updateMarkers(next.devices, next.lastUsedPosition);
        final region = _getCurrentRegionKey();
        if (next.devices.isNotEmpty) {
          OfflineMapManager.cacheMapData(region, next.devices);
        }
        if (_isMapReady) {
          if (next.devices.isNotEmpty) {
            _fitBounds(_filterDevicesBySearch(next.devices));
          } else if (next.lastUsedPosition != null) {
            _animateToPosition(
              LatLng(next.lastUsedPosition!.latitude,
                  next.lastUsedPosition!.longitude),
              zoom: 13.0,
            );
          }
          // If the state goes back to initial/fetching/loading, we don't necessarily need to animate,
          // but _updateMarkers handles clearing if devices list is empty.
        }
      }
    });

    final filteredDevices = _filterDevicesBySearch(chargeNowState.devices);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kInitialCameraPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            compassEnabled: false,
            mapToolbarEnabled: false,
            buildingsEnabled: false,
            trafficEnabled: false,
            indoorViewEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(6.0, 18.0),
            onMapCreated: (GoogleMapController controller) {
              if (!_mapControllerCompleter.isCompleted) {
                _mapControllerCompleter.complete(controller);
              }
              _googleMapController = controller;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _onMapReady();
              });
            },
            onCameraMove: _onCameraMove,
          ),

          // New Search Field Widget with SafeArea
          SafeArea(
            child: ChargingStationSearchField(
              controller: _searchController,
              searchQuery: _searchQuery,
              onClear: _onSearchClear,
              isLoading: chargeNowState.status ==
                      ChargeNowDeviceStatus.fetchingLocation ||
                  chargeNowState.status == ChargeNowDeviceStatus.loading,
            ),
          ),

          Positioned(
            right: 16,
            bottom: 220 + MediaQuery.of(context).padding.bottom,
            child: AnimatedOpacity(
              opacity: chargeNowState.status ==
                          ChargeNowDeviceStatus.fetchingLocation ||
                      chargeNowState.status == ChargeNowDeviceStatus.loading
                  ? 0.7
                  : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon:
                          const Icon(Icons.my_location, color: Colors.black87),
                      onPressed: () {
                        LocationDebouncer.debounce(() {
                          chargeNowNotifier.fetchDevicesNearCurrentLocation();
                        });
                      },
                      tooltip: AppLocale.centerOnMyLocation.getString(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.black87),
                      onPressed: () {
                        // MODIFICATION START
                        LocationDebouncer.debounce(() {
                          chargeNowNotifier.resetState(); // Reset state
                          // The forceRefresh is implied by resetting the state,
                          // but keeping it doesn't hurt.
                          chargeNowNotifier.fetchDevicesNearCurrentLocation(
                              forceRefresh: true);
                        });
                        // MODIFICATION END
                      },
                      tooltip: AppLocale.refreshNearby.getString(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (chargeNowState.status == ChargeNowDeviceStatus.fetchingLocation)
            buildStatusOverlay(
              message: AppLocale.fetchingLocation.getString(context),
              isLoading: true,
            ),
          if (chargeNowState.status == ChargeNowDeviceStatus.loading &&
              chargeNowState.devices.isEmpty)
            buildStatusOverlay(
              message: AppLocale.findingNearbyStations.getString(context),
              isLoading: true,
            ),
          if (chargeNowState.status == ChargeNowDeviceStatus.empty &&
              _searchQuery.isEmpty)
            buildStatusOverlay(
              message: AppLocale.noStationsNearby.getString(context),
              icon: Icons.battery_alert_rounded,
            ),
          if (chargeNowState.status == ChargeNowDeviceStatus.error &&
              chargeNowState.devices.isEmpty)
            buildStatusOverlay(
              message: chargeNowState.errorMsg!.contains("network")
                  ? AppLocale.networkError.getString(context)
                  : chargeNowState.errorMsg ??
                      AppLocale.failedToLoadStations.getString(context),
              icon: Icons.error_outline_rounded,
              isError: true,
            ),
          if (_searchQuery.isNotEmpty && filteredDevices.isEmpty)
            buildStatusOverlay(
              message: AppLocale.noStationsMatching
                  .getString(context)
                  .replaceAll('{query}', _searchQuery),
              icon: Icons.search_off,
            ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: SafeArea(
              child: CustomNavigationContainer(),
            ),
          ),
        ],
      ),
    );
  }
}
