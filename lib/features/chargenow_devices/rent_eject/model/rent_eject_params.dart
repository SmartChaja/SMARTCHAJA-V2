
class RentEjectParams {
  final String cabinetId;
  final String rentOrderId;
  final String slotNum;

  RentEjectParams({
    required this.cabinetId,
    required this.rentOrderId,
    required this.slotNum,
  });

  Map<String, String> toQueryParameters() {
    return {
      'cabinetid': cabinetId,
      'rentOrderId': rentOrderId,
      'slotNum': slotNum,
    };
  }
}