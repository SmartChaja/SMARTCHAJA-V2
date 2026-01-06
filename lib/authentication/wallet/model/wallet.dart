
enum TransactionStatus {
  pending,
  completed,
  confirmed,
  failed,
  unknown,
}


TransactionStatus stringToTransactionStatus(String? statusString) {
  if (statusString == null) return TransactionStatus.unknown;
  switch (statusString.toLowerCase()) {
    case 'pending':
      return TransactionStatus.pending;
    case 'completed':
      return TransactionStatus.completed;
    case 'confirmed':
      return TransactionStatus.confirmed;
    case 'failed':
      return TransactionStatus.failed;
    default:
      return TransactionStatus.unknown;
  }
}

// Updated Transaction class to include status
class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime timestamp;
  final String location; // This corresponds to 'provider'
  final TransactionStatus status; // New field for status

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.status, // Make it required
  });
}

// Existing TransactionType enum
enum TransactionType { deposit, charge, refund }
