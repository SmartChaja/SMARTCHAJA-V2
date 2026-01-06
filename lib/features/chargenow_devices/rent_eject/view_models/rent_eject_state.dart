import 'package:smart_chaja/features/chargenow_devices/rent_eject/model/rent_eject_response.dart';

enum RentEjectStatus { initial, loading, success, error }

class RentEjectState {
  final RentEjectStatus status;
  final RentEjectResponse? rentEjectResponse;
  final String? errorMsg;
  final dynamic validationDetails;

  RentEjectState({
    required this.status,
    this.rentEjectResponse,
    this.errorMsg,
    this.validationDetails,
  });

  RentEjectState copyWith({
    RentEjectStatus? status,
    RentEjectResponse? rentEjectResponse,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return RentEjectState(
      status: clearAll ? RentEjectStatus.initial : status ?? this.status,
      rentEjectResponse: clearAll ? null : rentEjectResponse ?? this.rentEjectResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}
