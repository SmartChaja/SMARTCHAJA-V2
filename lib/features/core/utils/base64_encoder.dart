// File: lib/core/utils/base64_encoder.dart
import 'dart:convert'; // This provides utf8 and base64

class Base64Encoder {
  // Ensure the method is static if you call it as Base64Encoder.encode()
  static String encode(String credentials) {
    // Get the bytes of the string in UTF-8
    List<int> stringBytes = utf8.encode(credentials);
    // Encode the UTF-8 bytes to Base64 string
    String base64String = base64.encode(stringBytes);
    return base64String;
  }

  // Optional: if you also need a decode method
  static String decode(String base64String) {
    List<int> decodedBytes = base64.decode(base64String);
    String originalString = utf8.decode(decodedBytes);
    return originalString;
  }
}