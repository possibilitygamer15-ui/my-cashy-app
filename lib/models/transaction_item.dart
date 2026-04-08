class TransactionItem {
  const TransactionItem({
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
    required this.status,
  });

  final String type;
  final double amount;
  final String description;
  final DateTime timestamp;
  final String status;

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      type: (map['type'] ?? '') as String,
      amount: ((map['amount'] ?? 0) as num).toDouble(),
      description: (map['description'] ?? '') as String,
      timestamp: DateTime.tryParse((map['timestamp'] ?? '') as String) ?? DateTime.now(),
      status: (map['status'] ?? 'success') as String,
    );
  }
}
