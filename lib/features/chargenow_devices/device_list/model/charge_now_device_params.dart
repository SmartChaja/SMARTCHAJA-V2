  enum CoordType {
    wgs84("WGS-84"),
    gcj02("GCJ-02"),
    bd09("BD-09");

    final String value;
    const CoordType(this.value);
    String toJson() => value;
  }

  class ChargeNowDeviceParams {
    final CoordType coordType;
    final String zoomLevel; // e.g., "5"
    final String lat;       // Latitude string
    final String lng;       // Longitude string
    final bool? showPrice;  // Optional, defaults to true

    ChargeNowDeviceParams({
      required this.coordType,
      required this.zoomLevel,
      required this.lat,
      required this.lng,
      this.showPrice,
    });

    Map<String, String> toQueryParameters() {
      final Map<String, String> params = {
        'coordType': coordType.toJson(),
        'zoomLevel': zoomLevel,
        'lat': lat,
        'lng': lng,
      };
      if (showPrice != null) {
        params['showPrice'] = showPrice.toString();
      }
      return params;
    }
  }
