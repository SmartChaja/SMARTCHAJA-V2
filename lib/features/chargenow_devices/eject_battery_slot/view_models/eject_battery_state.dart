import 'package:smart_chaja/features/chargenow_devices/eject_battery_slot/model/eject_battery_response.dart';

enum EjectBatteryStatus { initial, loading, success, error }

class EjectBatteryState {
  final EjectBatteryStatus status;
  final EjectBatteryResponse? ejectResponse;
  final String? errorMsg;
  final dynamic validationDetails;

  EjectBatteryState({
    required this.status,
    this.ejectResponse,
    this.errorMsg,
    this.validationDetails,
  });

  EjectBatteryState copyWith({
    EjectBatteryStatus? status,
    EjectBatteryResponse? ejectResponse,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return EjectBatteryState(
      status: clearAll ? EjectBatteryStatus.initial : status ?? this.status,
      ejectResponse: clearAll ? null : ejectResponse ?? this.ejectResponse,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}