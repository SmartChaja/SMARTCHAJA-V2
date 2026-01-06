String generateCustomerId() {
  // Generate a unique customer ID
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String generateOrderId() {
  // Generate a unique order ID
  return DateTime.now().millisecondsSinceEpoch.toString();
}