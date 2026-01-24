class Borrow {
  final String id;
  final String person;
  final double amount;
  final DateTime date;

  Borrow({
    required this.id,
    required this.person,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person': person,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Borrow.fromMap(Map<String, dynamic> map) {
    return Borrow(
      id: map['id'],
      person: map['person'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }
}
