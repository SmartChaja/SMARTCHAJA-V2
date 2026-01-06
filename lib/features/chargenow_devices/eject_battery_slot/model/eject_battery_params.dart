class EjectBatteryParams {
  final String cabinetId;
  final String? slotNum;

  EjectBatteryParams({
    required this.cabinetId,
    this.slotNum,
  });

  Map<String, String> toQueryParameters() {
    final params = {'cabinetid': cabinetId};
    if (slotNum != null && slotNum!.isNotEmpty) {
      params['slotNum'] = slotNum!;
    }
    return params;
  }
}