class Expense {
  final int? id;
  final String date;
  final String day;
  final double rickshaw;
  final double lunch;
  final double tea;
  final double general;
  final double extra;
  final String extraDetails;
  final String paymentMode; // Cash, JazzCash, EasyPaisa, Bank

  Expense({
    this.id,
    required this.date,
    required this.day,
    this.rickshaw = 0.0,
    this.lunch = 0.0,
    this.tea = 0.0,
    this.general = 0.0,
    this.extra = 0.0,
    this.extraDetails = '',
    this.paymentMode = 'Cash',
  });

  double get total => rickshaw + lunch + tea + general + extra;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'day': day,
      'rickshaw': rickshaw,
      'lunch': lunch,
      'tea': tea,
      'general': general,
      'extra': extra,
      'extraDetails': extraDetails,
      'paymentMode': paymentMode,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      date: map['date'] ?? '',
      day: map['day'] ?? '',
      rickshaw: (map['rickshaw'] as num?)?.toDouble() ?? 0.0,
      lunch: (map['lunch'] as num?)?.toDouble() ?? 0.0,
      tea: (map['tea'] as num?)?.toDouble() ?? 0.0,
      general: (map['general'] as num?)?.toDouble() ?? 0.0,
      extra: (map['extra'] as num?)?.toDouble() ?? 0.0,
      extraDetails: map['extraDetails'] ?? '',
      paymentMode: map['paymentMode'] ?? 'Cash',
    );
  }
}
