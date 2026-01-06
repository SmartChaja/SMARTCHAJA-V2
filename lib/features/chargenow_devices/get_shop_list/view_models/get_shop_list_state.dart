enum GetShopListStatus { initial, loading, success, error }

class GetShopListState {
  final GetShopListStatus status;
  final List<Map<String, dynamic>>? shops;
  final String? errorMsg;
  final dynamic validationDetails;

  GetShopListState({
    required this.status,
    this.shops,
    this.errorMsg,
    this.validationDetails,
  });

  GetShopListState copyWith({
    GetShopListStatus? status,
    List<Map<String, dynamic>>? shops,
    String? errorMsg,
    bool clearAll = false,
  }) {
    return GetShopListState(
      status: clearAll ? GetShopListStatus.initial : status ?? this.status,
      shops: clearAll ? null : shops ?? this.shops,
      errorMsg: clearAll ? null : errorMsg ?? this.errorMsg,
      validationDetails: clearAll ? null : validationDetails ?? this.validationDetails,
    );
  }
}
