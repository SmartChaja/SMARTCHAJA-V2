  class CreateRentOrderParams {
    final String deviceId;
    final String callbackURL;

    CreateRentOrderParams({
      required this.deviceId,
      required this.callbackURL,
    });

    Map<String, String> toQueryParameters() {
      return {
        'deviceId': deviceId,
        'callbackURL': callbackURL,
      };
    }
  }
  