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

  /// Calculate reminder time in minutes before rental ends
  /// Based on rental duration:
  /// - < 1 hour: remind at 25% before end
  /// - 1-6 hours: remind 15 mins before end
  /// - >= 6 hours: remind at 10% before end
  int get reminderMinutes {
    final durationMinutes = durationDays * 24 * 60; // Convert days to minutes

    if (durationMinutes < 60) {
      // Less than 1 hour: remind at 25% before end
      return (durationMinutes * 0.25).round();
    } else if (durationMinutes <= 360) {
      // 1-6 hours: remind 15 minutes before end
      return 15;
    } else {
      // 6+ hours: remind at 10% before end
      return (durationMinutes * 0.10).round();
    }
  }

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
