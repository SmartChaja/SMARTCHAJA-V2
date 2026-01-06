class Plan {
  final String id;
  final String name;
  final int durationDays;
  final double price;
  final String currency;

  Plan({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    required this.currency,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      durationDays: json['duration_days'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'TZS',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration_days': durationDays,
      'price': price,
      'currency': currency,
    };
  }
}