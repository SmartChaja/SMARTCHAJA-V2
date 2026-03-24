import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/asn1.dart';

class EncryptionService {
  /// Encrypts the API key using RSA encryption with the given public key
  /// Returns the encrypted key as a Base64 encoded string
  /// Uses PKCS#1 v1.5 padding as required by M-Pesa API
  static String encryptWithPublicKey(String publicKeyPem, String plainText) {
    try {
      // Parse the public key
      final publicKey = _parsePublicKeyFromString(publicKeyPem);

      // Convert plaintext to bytes
      final plaintextBytes = utf8.encode(plainText);

      print('[EncryptionDebug] ═══════════════════════════════════');
      print(
          '[EncryptionDebug] Input plaintext length: [32m${plainText.length}[0m');
      print('[EncryptionDebug] Input bytes length: ${plaintextBytes.length}');
      print(
          '[EncryptionDebug] RSA key modulus bits: ${publicKey.modulus?.bitLength}');
      print('[EncryptionDebug] RSA key exponent: ${publicKey.exponent}');

      // Manual PKCS#1 v1.5 padding
      final modulusLen = (publicKey.modulus!.bitLength + 7) ~/ 8;
      if (plaintextBytes.length > modulusLen - 11) {
        throw Exception('Plaintext too long for RSA PKCS#1 v1.5 padding');
      }
      // Generate nonzero random bytes for padding
      final rng = Uint8List(modulusLen - plaintextBytes.length - 3);
      for (int i = 0; i < rng.length; i++) {
        int val;
        do {
          val = (DateTime.now().microsecondsSinceEpoch + i * 31) % 256;
        } while (val == 0);
        rng[i] = val;
      }
      final padded = Uint8List(modulusLen)
        ..[0] = 0x00
        ..[1] = 0x02
        ..setRange(2, 2 + rng.length, rng)
        ..[2 + rng.length] = 0x00
        ..setRange(3 + rng.length, modulusLen, plaintextBytes);

      // Encrypt with raw RSA
      final cipher = RSAEngine()
        ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
      final ciphertext = cipher.process(padded);

      print('[EncryptionDebug] Ciphertext length: ${ciphertext.length}');
      print(
          '[EncryptionDebug] Ciphertext hex (first 32 bytes): ${_bytesToHex(ciphertext.sublist(0, 32))}');

      // Encode as Base64 for transmission
      final encoded = base64.encode(ciphertext);
      print('[EncryptionDebug] Base64 encoded length: ${encoded.length}');
      print(
          '[EncryptionDebug] Base64 first 50 chars: ${encoded.substring(0, 50)}...');
      print(
          '[EncryptionDebug] Base64 last 20 chars: ...${encoded.substring(encoded.length - 20)}');
      print('[EncryptionDebug] ═══════════════════════════════════');

      // Print the full encrypted API key for direct comparison with Node.js
      print('[VodacomDebug] Dart encrypted_api_key: $encoded');

      return encoded;
    } catch (e) {
      throw Exception('RSA encryption failed: $e');
    }
  }

  /// Parses an RSA public key from Base64 (with or without PEM headers)
  static RSAPublicKey _parsePublicKeyFromString(String keyString) {
    try {
      // Remove any PEM headers
      String cleanKey = keyString
          .replaceAll(RegExp(r'-----[A-Z ]*-----'), '')
          .replaceAll(RegExp(r'\s'), '');

      // Decode from Base64
      final keyBytes = base64.decode(cleanKey);

      // Try to parse as DER/ASN.1
      return _parsePublicKeyFromDER(keyBytes);
    } catch (e) {
      throw Exception('Failed to parse public key: $e');
    }
  }

  /// Parses DER-encoded RSA public key
  /// Supports both SubjectPublicKeyInfo (PKCS#8) and raw PKCS#1 formats
  static RSAPublicKey _parsePublicKeyFromDER(List<int> derBytes) {
    try {
      final parser = ASN1Parser(Uint8List.fromList(derBytes));
      final root = parser.nextObject();

      if (root is! ASN1Sequence) {
        throw Exception('DER root is not a sequence: ${root.runtimeType}');
      }

      // Debug: Log the actual structure
      final elemTypesList =
          root.elements?.map((e) => e.runtimeType.toString()).toList() ?? [];
      print('[VodacomDebug] Root sequence has ${root.elements?.length ?? 0} '
          'elements: $elemTypesList');

      // Try to extract modulus and exponent
      final result = _extractRSAComponents(root);

      if (result == null) {
        // Provide detailed error with actual structure
        print('[VodacomDebug] Failed to extract RSA components');
        throw Exception('Could not extract RSA modulus and exponent. '
            'Root sequence has ${root.elements?.length ?? 0} elements: $elemTypesList');
      }

      print('[VodacomDebug] Successfully extracted RSA modulus and exponent');
      return RSAPublicKey(
          result['modulus'] as BigInt, result['exponent'] as BigInt);
    } catch (e) {
      throw Exception('DER parse failed: $e');
    }
  }

  /// Extracts modulus and exponent from an ASN1Sequence
  /// Returns null if extraction fails
  static Map<String, BigInt>? _extractRSAComponents(ASN1Sequence seq) {
    if (seq.elements == null || seq.elements!.length < 2) {
      return null;
    }

    final elements = seq.elements!;
    BigInt? modulus;
    BigInt? exponent;

    // Case 1: SubjectPublicKeyInfo - SEQUENCE { AlgorithmIdentifier, BIT STRING { RSAPublicKey } }
    if (elements.length >= 2 && elements[1] is ASN1BitString) {
      final bitString = elements[1] as ASN1BitString;
      print('[VodacomDebug] Found BIT STRING at position 1');

      // BIT STRING in ASN1 can have elements if parsed from DER
      if (bitString.elements != null && bitString.elements!.isNotEmpty) {
        print(
            '[VodacomDebug] BIT STRING has ${bitString.elements!.length} nested elements');

        // First element might be the RSA key sequence
        if (bitString.elements![0] is ASN1Sequence) {
          final innerSeq = bitString.elements![0] as ASN1Sequence;
          print('[VodacomDebug] Found sequence in BIT STRING elements');

          if (innerSeq.elements != null && innerSeq.elements!.length >= 2) {
            if (innerSeq.elements![0] is ASN1Integer &&
                innerSeq.elements![1] is ASN1Integer) {
              modulus = (innerSeq.elements![0] as ASN1Integer).integer;
              exponent = (innerSeq.elements![1] as ASN1Integer).integer;
              print('[VodacomDebug] ✓ Extracted from BIT STRING elements: '
                  'mod=${modulus?.bitLength} bits, exp=$exponent');

              if (modulus != null && exponent != null) {
                return {'modulus': modulus, 'exponent': exponent};
              }
            }
          }
        }
      }

      // Try string values approach
      List<int>? bitBytes = bitString.stringValues;
      print(
          '[VodacomDebug] bitString.stringValues = ${bitBytes != null ? 'length ${bitBytes.length}' : 'null'}');

      if (bitBytes != null && bitBytes.isNotEmpty) {
        print(
            '[VodacomDebug] Trying stringValues extraction (first byte: ${bitBytes[0]})');
        try {
          // BIT STRING format: first byte is unused bits count
          int startIdx = bitBytes[0] <= 7 ? 1 : 0;
          print(
              '[VodacomDebug] Start index: $startIdx (unused bits: ${bitBytes[0]})');

          if (startIdx < bitBytes.length) {
            final rsaKeyBytes = Uint8List.fromList(bitBytes.sublist(startIdx));
            print(
                '[VodacomDebug] Parsing ${rsaKeyBytes.length} bytes from BIT STRING');

            try {
              final rsaParser = ASN1Parser(rsaKeyBytes);
              final rsaSeq = rsaParser.nextObject();
              print('[VodacomDebug] Parsed object type: ${rsaSeq.runtimeType}');

              if (rsaSeq is ASN1Sequence &&
                  rsaSeq.elements != null &&
                  rsaSeq.elements!.length >= 2) {
                print(
                    '[VodacomDebug] RSA sequence has ${rsaSeq.elements!.length} elements');

                if (rsaSeq.elements![0] is ASN1Integer &&
                    rsaSeq.elements![1] is ASN1Integer) {
                  final mod = rsaSeq.elements![0] as ASN1Integer;
                  final exp = rsaSeq.elements![1] as ASN1Integer;
                  modulus = mod.integer;
                  exponent = exp.integer;
                  print('[VodacomDebug] ✓ Extracted from stringValues: '
                      'mod=${modulus?.bitLength} bits, exp=$exponent');

                  if (modulus != null && exponent != null) {
                    return {'modulus': modulus, 'exponent': exponent};
                  }
                }
              }
            } catch (e) {
              print('[VodacomDebug] stringValues parsing failed: $e');
            }
          }
        } catch (e) {
          print('[VodacomDebug] stringValues extraction error: $e');
        }
      }
    }

    // Case 2: Direct integers in the main sequence (raw PKCS#1)
    if (modulus == null || exponent == null) {
      print('[VodacomDebug] Trying Case 2: Direct integers');
      if (elements[0] is ASN1Integer && elements[1] is ASN1Integer) {
        final mod = elements[0] as ASN1Integer;
        final exp = elements[1] as ASN1Integer;
        modulus = mod.integer;
        exponent = exp.integer;

        if (modulus != null &&
            exponent != null &&
            modulus != BigInt.zero &&
            exponent != BigInt.zero) {
          print('[VodacomDebug] ✓ Extracted from Case 2');
          return {'modulus': modulus, 'exponent': exponent};
        }
      }
    }

    // Case 3: Nested sequence (second element is a SEQUENCE, not BIT STRING)
    if (modulus == null || exponent == null) {
      print('[VodacomDebug] Trying Case 3: Nested sequence');
      if (elements.length >= 2 && elements[1] is ASN1Sequence) {
        final innerSeq = elements[1] as ASN1Sequence;
        return _extractRSAComponents(innerSeq);
      }
    }

    // Case 4: Maybe the entire key data is wrapped differently
    // Try parsing the first element as potential RSA data
    if (modulus == null || exponent == null) {
      print('[VodacomDebug] Trying Case 4: First element as RSA');
      if (elements[0] is ASN1Sequence) {
        return _extractRSAComponents(elements[0] as ASN1Sequence);
      }
    }

    print('[VodacomDebug] All extraction cases failed');
    return null;
  }

  /// Helper to convert bytes to hex string for debugging
  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
