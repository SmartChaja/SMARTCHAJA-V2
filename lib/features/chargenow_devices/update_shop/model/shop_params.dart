class ShopParams {
  final String pNewid;
  final String pName;
  final int? pSceneType;
  final int? pStoreType;
  final String? pAddress;
  final String pJingdu;
  final String pWeidu;
  final int? pAuditor;
  final String? pContent;
  final String? pCurrency;
  final String? pLocationId;
  final String? pLogo;

  ShopParams({
    required this.pNewid,
    required this.pName,
    this.pSceneType,
    this.pStoreType,
    this.pAddress,
    required this.pJingdu,
    required this.pWeidu,
    this.pAuditor,
    this.pContent,
    this.pCurrency,
    this.pLocationId,
    this.pLogo,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'pNewid': pNewid,
      'pName': pName,
      'pJingdu': pJingdu,
      'pWeidu': pWeidu,
    };
    if (pSceneType != null) map['pSceneType'] = pSceneType;
    if (pStoreType != null) map['pStoreType'] = pStoreType;
    if (pAddress != null && pAddress!.isNotEmpty) map['pAddress'] = pAddress;
    if (pAuditor != null) map['pAuditor'] = pAuditor;
    if (pContent != null && pContent!.isNotEmpty) map['pContent'] = pContent;
    if (pCurrency != null && pCurrency!.isNotEmpty) map['pCurrency'] = pCurrency;
    if (pLocationId != null && pLocationId!.isNotEmpty) map['pLocationId'] = pLocationId;
    if (pLogo != null && pLogo!.isNotEmpty) map['pLogo'] = pLogo;
    return map;
  }
}