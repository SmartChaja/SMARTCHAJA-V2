  class PriceStrategyInfo {
    final int? depositAmount;
    final int? priceMinute; // Price per minute (integer, likely in smallest currency unit, e.g., cents)
    final int? autoRefund; // Boolean-like integer (0 or 1)
    final int? timeoutAmount;
    final int? timeoutDay;
    final int? dailyMaxPrice;
    final int? freeMinutes;
    final String? currencySymbol;
    final num? price; // Unit price (can be int or double)
    final String? name;
    final String? currency; // 3 letter currency code (e.g., "USD")
    final String? shopId;

    PriceStrategyInfo({
      this.depositAmount,
      this.priceMinute,
      this.autoRefund,
      this.timeoutAmount,
      this.timeoutDay,
      this.dailyMaxPrice,
      this.freeMinutes,
      this.currencySymbol,
      this.price,
      this.name,
      this.currency,
      this.shopId,
    });

    factory PriceStrategyInfo.fromJson(Map<String, dynamic> json) {
      return PriceStrategyInfo(
        depositAmount: json['depositAmount'],
        priceMinute: json['priceMinute'],
        autoRefund: json['autoRefund'],
        timeoutAmount: json['timeoutAmount'],
        timeoutDay: json['timeoutDay'],
        dailyMaxPrice: json['dailyMaxPrice'],
        freeMinutes: json['freeMinutes'],
        currencySymbol: json['currencySymbol'],
        price: json['price'],
        name: json['name'],
        currency: json['currency'],
        shopId: json['shopId'],
      );
    }
  }

  class ShopInfo { // Different from ShopData in list response
    final String? address;
    final String? priceMinute; // Price per minute (string, might include currency or be just number)
    final String? city;
    final int? dailyMaxPrice;
    final String? latitude;
    final String? openingTime;
    final int? freeMinutes;
    final String? icon;
    final String? content; // Store Description
    final String? province;
    final num? price; // Unit price
    final String? name;
    final int? deposit;
    final String? logo;
    final String? id; // Shop ID
    final String? region;
    final String? longitude;

    ShopInfo({
      this.address,
      this.priceMinute,
      this.city,
      this.dailyMaxPrice,
      this.latitude,
      this.openingTime,
      this.freeMinutes,
      this.icon,
      this.content,
      this.province,
      this.price,
      this.name,
      this.deposit,
      this.logo,
      this.id,
      this.region,
      this.longitude,
    });

    factory ShopInfo.fromJson(Map<String, dynamic> json) {
      return ShopInfo(
        address: json['address'],
        priceMinute: json['priceMinute'],
        city: json['city'],
        dailyMaxPrice: json['dailyMaxPrice'],
        latitude: json['latitude'],
        openingTime: json['openingTime'],
        freeMinutes: json['freeMinutes'],
        icon: json['icon'],
        content: json['content'],
        province: json['province'],
        price: json['price'],
        name: json['name'],
        deposit: json['deposit'],
        logo: json['logo'],
        id: json['id'],
        region: json['region'],
        longitude: json['longitude'],
      );
    }
  }

  class BatteryInfo {
    final int? slotNum;
    final int? vol; // Voltage
    final String? batteryId;

    BatteryInfo({this.slotNum, this.vol, this.batteryId});

    factory BatteryInfo.fromJson(Map<String, dynamic> json) {
      return BatteryInfo(
        slotNum: json['slotNum'],
        vol: json['vol'],
        batteryId: json['batteryId'],
      );
    }
  }

  class CabinetInfo { // Different from CabinetData in list response
    final String? ip;
    final String? remark;
    final String? type; // Cabinet type
    final int? slots;
    final String? qrCode;
    final bool? online;
    final int? emptySlots;
    final int? busySlots;
    final String? id; // Cabinet ID (matches deviceId from request)
    final String? shopId;
    final String? signal;
    final String? posDeviceId;

    CabinetInfo({
      this.ip,
      this.remark,
      this.type,
      this.slots,
      this.qrCode,
      this.online,
      this.emptySlots,
      this.busySlots,
      this.id,
      this.shopId,
      this.signal,
      this.posDeviceId,
    });

    factory CabinetInfo.fromJson(Map<String, dynamic> json) {
      return CabinetInfo(
        ip: json['ip'],
        remark: json['remark'],
        type: json['type'],
        slots: json['slots'],
        qrCode: json['qrCode'],
        online: json['online'],
        emptySlots: json['emptySlots'],
        busySlots: json['busySlots'],
        id: json['id'],
        shopId: json['shopId'],
        signal: json['signal'],
        posDeviceId: json['posDeviceId'],
      );
    }
  }

  class DeviceInfoData {
    final PriceStrategyInfo? priceStrategy;
    final ShopInfo? shop;
    final List<BatteryInfo> batteries;
    final CabinetInfo? cabinet;

    DeviceInfoData({
      this.priceStrategy,
      this.shop,
      this.batteries = const [],
      this.cabinet,
    });

    factory DeviceInfoData.fromJson(Map<String, dynamic> json) {
      return DeviceInfoData(
        priceStrategy: json['priceStrategy'] != null
            ? PriceStrategyInfo.fromJson(json['priceStrategy'])
            : null,
        shop: json['shop'] != null ? ShopInfo.fromJson(json['shop']) : null,
        batteries: (json['batteries'] as List<dynamic>?)
                ?.map((item) => BatteryInfo.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        cabinet: json['cabinet'] != null ? CabinetInfo.fromJson(json['cabinet']) : null,
      );
    }
  }

  class ChargeNowDeviceInfoResponse {
    final String msg;
    final int code; // 0 for success
    final DeviceInfoData? data; // Data can be null if code is not 0

    ChargeNowDeviceInfoResponse({
      required this.msg,
      required this.code,
      this.data,
    });

    factory ChargeNowDeviceInfoResponse.fromJson(Map<String, dynamic> json) {
      return ChargeNowDeviceInfoResponse(
        msg: json['msg'] ?? 'No message',
        code: json['code'] ?? -1,
        data: json['data'] != null ? DeviceInfoData.fromJson(json['data']) : null,
      );
    }
  }
  