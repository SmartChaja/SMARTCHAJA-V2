// lib/features/wallet/provider/wallet_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_chaja/features/wallet/service/wallet_service.dart';

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService(FirebaseFirestore.instance);
});