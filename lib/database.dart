// database.dart - локальна «база даних» карток
class BankAccount {
  final String fullName;
  final String passportSerial;
  final String idNumber;
  final String phone;
  final String cardNumber;
  final String cvv;
  final String pin;
  final double balance;

  BankAccount({
    required this.fullName,
    required this.passportSerial,
    required this.idNumber,
    required this.phone,
    required this.cardNumber,
    required this.cvv,
    required this.pin,
    required this.balance,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'passportSerial': passportSerial,
        'idNumber': idNumber,
        'phone': phone,
        'cardNumber': cardNumber,
        'cvv': cvv,
        'pin': pin,
        'balance': balance,
      };

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      fullName: json['fullName'],
      passportSerial: json['passportSerial'],
      idNumber: json['idNumber'],
      phone: json['phone'],
      cardNumber: json['cardNumber'],
      cvv: json['cvv'],
      pin: json['pin'],
      balance: (json['balance'] as num).toDouble(),
    );
    
  }
}
// Додайте це в lib/database.dart

class TransactionLog {
  final String action;      // Тип дії (Зняття, Переказ, Перевірка балансу тощо)
  final String cardNumber;  // Номер картки, з якою працювали
  final double? amount;     // Сума (якщо є)
  final DateTime dateTime;  // Дата та час
  final String details;     // Додаткова інформація

  TransactionLog({
    required this.action,
    required this.cardNumber,
    this.amount,
    required this.dateTime,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'cardNumber': cardNumber,
        'amount': amount,
        'dateTime': dateTime.toIso8601String(),
        'details': details,
      };

  factory TransactionLog.fromJson(Map<String, dynamic> json) {
    return TransactionLog(
      action: json['action'],
      cardNumber: json['cardNumber'],
      amount: json['amount'],
      dateTime: DateTime.parse(json['dateTime']),
      details: json['details'],
    );
  }
}

