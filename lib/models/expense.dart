class Expense {
  final int? id;
  final String title;
  final int amountPaise;
  final String category;
  final DateTime date;
  final String? description;

  // 'inward' or 'outward'
  final String transactionType;

  const Expense({
    this.id,
    required this.title,
    required this.amountPaise,
    required this.category,
    required this.date,
    this.description,
    this.transactionType = 'outward',
  });

  bool get isInward => transactionType == 'inward';

  double get amount => amountPaise / 100;

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount_paise': amountPaise,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
      'transaction_type': transactionType,
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int,
      title: map['title'] as String,
      amountPaise: map['amount_paise'] as int,
      category: map['category'] as String,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      transactionType:
      map['transaction_type'] as String? ?? 'outward',
    );
  }
}