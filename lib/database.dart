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

// Приклад трьох записів у «базі»
final List<BankAccount> mockAccounts = [
  BankAccount(
    fullName: 'Mike Oxlong',
    passportSerial: 'AB1234',
    idNumber: '1234567890',
    phone: '+380990000001',
    cardNumber: '1111111111111111',
    cvv: '123',
    pin: '1111',
    balance: 1500.0,
  ),
  BankAccount(
    fullName: 'Kys Benis',
    passportSerial: 'CD6543',
    idNumber: '0987654321',
    phone: '+380990000002',
    cardNumber: '1111111111111112',
    cvv: '456',
    pin: '2222',
    balance: 3000.0,
  ),
  BankAccount(
    fullName: 'Sug Madig',
    passportSerial: 'EF9876',
    idNumber: '1122334455',
    phone: '+380990000003',
    cardNumber: '1111111111111113',
    cvv: '789',
    pin: '3333',
    balance: 750.0,
  ),
];
