class PriceData {
  final int priceId;
  final String? freeDuration;
  final String? price;
  final String? chargeUnit;
  final String? dailyCapAmount;
  final String? deposit;

  PriceData({
    required this.priceId,
    this.freeDuration,
    this.price,
    this.chargeUnit,
    this.dailyCapAmount,
    this.deposit,
  });

  factory PriceData.fromJson(Map<String, dynamic> json) {
    return PriceData(
      priceId: json['priceId'] ?? 0,
      freeDuration: json['freeDuration'],
      price: json['price'],
      chargeUnit: json['chargeUnit'],
      dailyCapAmount: json['dailyCapAmount'],
      deposit: json['deposit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'priceId': priceId,
      'freeDuration': freeDuration,
      'price': price,
      'chargeUnit': chargeUnit,
      'dailyCapAmount': dailyCapAmount,
      'deposit': deposit,
    };
  }
}

class CabinetData {
  final String batteryNum;
  final String freeNum;
  final String infoStatus;

  CabinetData({
    required this.batteryNum,
    required this.freeNum,
    required this.infoStatus,
  });

  factory CabinetData.fromJson(Map<String, dynamic> json) {
    return CabinetData(
      batteryNum: json['batteryNum'] ?? '0',
      freeNum: json['freeNum'] ?? '0',
      infoStatus: json['infoStatus'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batteryNum': batteryNum,
      'freeNum': freeNum,
      'infoStatus': infoStatus,
    };
  }
}

class ShopData {
  final String id;
  final String shopName;
  final String shopAddress;
  final String? mobile;
  final String? distance;
  final String longitude;
  final String latitude;
  final String? shopBanner;
  final String? shopIcon;
  final num distanceNumber;
  final String? sceneType;

  ShopData({
    required this.id,
    required this.shopName,
    required this.shopAddress,
    this.mobile,
    this.distance,
    required this.longitude,
    required this.latitude,
    this.shopBanner,
    this.shopIcon,
    required this.distanceNumber,
    this.sceneType,
  });

  factory ShopData.fromJson(Map<String, dynamic> json) {
    return ShopData(
      id: json['id'] ?? 'unknown_shop_id',
      shopName: json['shopName'] ?? 'Unknown Shop',
      shopAddress: json['shopAddress'] ?? 'No Address',
      mobile: json['mobile'],
      distance: json['distance'],
      longitude: json['longitude'] ?? '0.0',
      latitude: json['latitude'] ?? '0.0',
      shopBanner: json['shopBanner'],
      shopIcon: json['shopIcon'],
      distanceNumber: json['distanceNumber'] ?? 0,
      sceneType: json['sceneType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopName': shopName,
      'shopAddress': shopAddress,
      'mobile': mobile,
      'distance': distance,
      'longitude': longitude,
      'latitude': latitude,
      'shopBanner': shopBanner,
      'shopIcon': shopIcon,
      'distanceNumber': distanceNumber,
      'sceneType': sceneType,
    };
  }
}

class DeviceListItem {
  final PriceData? price;
  final CabinetData? cabinet;
  final ShopData? shop;

  DeviceListItem({
    this.price,
    this.cabinet,
    this.shop,
  });

  factory DeviceListItem.fromJson(Map<String, dynamic> json) {
    return DeviceListItem(
      price: json['price'] != null ? PriceData.fromJson(json['price']) : null,
      cabinet: json['cabinet'] != null ? CabinetData.fromJson(json['cabinet']) : null,
      shop: json['shop'] != null ? ShopData.fromJson(json['shop']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price?.toJson(),
      'cabinet': cabinet?.toJson(),
      'shop': shop?.toJson(),
    };
  }
}

class ChargeNowDeviceListResponse {
  final String msg;
  final int code;
  final List<DeviceListItem> list;

  ChargeNowDeviceListResponse({
    required this.msg,
    required this.code,
    required this.list,
  });

  factory ChargeNowDeviceListResponse.fromJson(Map<String, dynamic> json) {
    return ChargeNowDeviceListResponse(
      msg: json['msg'] ?? 'No message',
      code: json['code'] ?? -1,
      list: (json['list'] as List<dynamic>?)
              ?.map((item) => DeviceListItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'msg': msg,
      'code': code,
      'list': list.map((item) => item.toJson()).toList(),
    };
  }
}