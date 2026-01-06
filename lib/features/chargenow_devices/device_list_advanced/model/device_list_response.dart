class DeviceData {
  final int? pId;
  final String? pType;
  final String? pCabinetid;
  final int? pTotal;
  final int? pBorrow;
  final int? pAlso;
  final String? pRegtime;
  final String? pStatus;
  final int? pLognum;
  final String? pLogtime;
  final String? pJson;
  final String? pCard;
  final String? pJingdu;
  final String? pWeidu;
  final String? pHash;
  final String? pHardwareInfo;
  final String? pCode;
  final int? pZujienum;
  final String? pInfostatus;
  final String? pSignal;
  final String? pUserip;
  final String? pPort;
  final String? pMyip;
  final String? pPosDeviceid;

  DeviceData({
    this.pId,
    this.pType,
    this.pCabinetid,
    this.pTotal,
    this.pBorrow,
    this.pAlso,
    this.pRegtime,
    this.pStatus,
    this.pLognum,
    this.pLogtime,
    this.pJson,
    this.pCard,
    this.pJingdu,
    this.pWeidu,
    this.pHash,
    this.pHardwareInfo,
    this.pCode,
    this.pZujienum,
    this.pInfostatus,
    this.pSignal,
    this.pUserip,
    this.pPort,
    this.pMyip,
    this.pPosDeviceid,
  });

  factory DeviceData.fromJson(Map<String, dynamic> json) {
    return DeviceData(
      pId: json['pId'] as int?,
      pType: json['pType'] as String?,
      pCabinetid: json['pCabinetid'] as String?,
      pTotal: json['pTotal'] as int?,
      pBorrow: json['pBorrow'] as int?,
      pAlso: json['pAlso'] as int?,
      pRegtime: json['pRegtime'] as String?,
      pStatus: json['pStatus'] as String?,
      pLognum: json['pLognum'] as int?,
      pLogtime: json['pLogtime'] as String?,
      pJson: json['pJson'] as String?,
      pCard: json['pCard'] as String?,
      pJingdu: json['pJingdu'] as String?,
      pWeidu: json['pWeidu'] as String?,
      pHash: json['pHash'] as String?,
      pHardwareInfo: json['pHardwareInfo'] as String?,
      pCode: json['pCode'] as String?,
      pZujienum: json['pZujienum'] as int?,
      pInfostatus: json['pInfostatus'] as String?,
      pSignal: json['pSignal'] as String?,
      pUserip: json['pUserip'] as String?,
      pPort: json['pPort'] as String?,
      pMyip: json['pMyip'] as String?,
      pPosDeviceid: json['pPosDeviceid'] as String?,
    );
  }
}

class DeviceListResponse {
  final String? msg;
  final int code; // 0 for success
  final List<DeviceData>? data;

  DeviceListResponse({
    this.msg,
    required this.code,
    this.data,
  });

  factory DeviceListResponse.fromJson(Map<String, dynamic> json) {
    return DeviceListResponse(
      msg: json['msg'] as String? ?? 'No message received',
      code: json['code'] is String ? int.parse(json['code']) : json['code'] ?? -1,
      data: json['data'] != null && json['code'].toString() == '0'
          ? (json['data'] as List<dynamic>)
              .map((item) => DeviceData.fromJson(item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}