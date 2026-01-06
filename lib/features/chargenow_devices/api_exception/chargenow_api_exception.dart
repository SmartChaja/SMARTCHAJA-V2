// File: lib/features/chargenow_devices/api_exception/chargenow_api_exception.dart
import 'dart:convert';

class ChargeNowApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? apiInternalCode; // For the 'code' field from ChargeNow API
  final dynamic errorDetail; // For raw 'detail' or 'msg'

  ChargeNowApiException({
    required this.message,
    this.statusCode,
    this.apiInternalCode,
    this.errorDetail,
  });

  @override
  String toString() {
    return 'ChargeNowApiException: $message ${statusCode != null ? "(Status: $statusCode)" : ""} ${apiInternalCode != null ? "(API Code: $apiInternalCode)" : ""} ${errorDetail != null ? "Detail: $errorDetail" : ""}';
  }

  factory ChargeNowApiException.fromResponse(int httpStatusCode, String responseBody) {
    String parsedMessage = "An error occurred with the ChargeNow API.";
    String? internalCode;
    dynamic detail;

    try {
      final jsonResponse = jsonDecode(responseBody);
      if (jsonResponse is Map<String, dynamic>) {
        parsedMessage = jsonResponse['msg'] ?? jsonResponse['detail'] ?? parsedMessage;
        internalCode = jsonResponse['code']?.toString();
        if (jsonResponse.containsKey('detail')) {
            detail = jsonResponse['detail'];
        } else if (jsonResponse.containsKey('msg')) {
            detail = jsonResponse['msg'];
        }
      }
    } catch (e) {
      // If parsing fails, use raw body as detail
      detail = responseBody;
      parsedMessage = "Received non-JSON error response from ChargeNow API.";
    }

    if (httpStatusCode == 400) {
      return ChargeNowBadRequestException(message: parsedMessage, detail: detail, apiInternalCode: internalCode);
    } else if (httpStatusCode == 401) {
      return ChargeNowUnauthorizedException(message: parsedMessage, detail: detail);
    } else if (httpStatusCode == 422) {
      return ChargeNowValidationException(message: parsedMessage, detail: detail, apiInternalCode: internalCode);
    } else if (httpStatusCode >= 500) {
      return ChargeNowServerException(message: parsedMessage, detail: detail, statusCodeFromSource: httpStatusCode);
    }
    return ChargeNowApiException(message: parsedMessage, statusCode: httpStatusCode, apiInternalCode: internalCode, errorDetail: detail);
  }
}

class ChargeNowBadRequestException extends ChargeNowApiException {
  ChargeNowBadRequestException({required super.message, dynamic detail, super.apiInternalCode})
      : super(statusCode: 400, errorDetail: detail);
}

class ChargeNowUnauthorizedException extends ChargeNowApiException {
  ChargeNowUnauthorizedException({required super.message, dynamic detail})
      : super(statusCode: 401, errorDetail: detail);
}

class ChargeNowValidationException extends ChargeNowApiException {
  ChargeNowValidationException({required super.message, dynamic detail, super.apiInternalCode})
      : super(statusCode: 422, errorDetail: detail);
}

class ChargeNowServerException extends ChargeNowApiException {
  ChargeNowServerException({required super.message, dynamic detail, int? statusCodeFromSource})
      : super(statusCode: statusCodeFromSource ?? 500, errorDetail: detail);
}

class ChargeNowNetworkException extends ChargeNowApiException {
  ChargeNowNetworkException({required String message}) : super(message: "Network error: $message");
}