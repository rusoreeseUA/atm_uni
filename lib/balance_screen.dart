import 'dart:math';
import 'package:atm_project_unic/services/atm_services.dart';
import 'package:atm_project_unic/card_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database.dart';

enum LoginMethod { cardPhone, pin }

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  LoginMethod _loginMethod = LoginMethod.cardPhone;
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _isSending = false;
  String? _generatedCode;
  BankAccount? _matchedAccount;

  // Форматування картки XXXX XXXX XXXX XXXX
 // Форматування картки XXXX XXXX XXXX XXXX
  String _formatCardNumber(String input) {
    // 1. Залишаємо тільки цифри
    String digits = input.replaceAll(RegExp(r'\D'), '');
    
    // 2. ОБМЕЖЕННЯ: беремо лише перші 16 символів
    if (digits.length > 16) {
      digits = digits.substring(0, 16);
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      // Додаємо пробіл після кожної 4-ї цифри, якщо це не кінець рядка
      if ((i + 1) % 4 == 0 && i + 1 != digits.length) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  BankAccount? _findAccountByCardAndPhone(String card, String phone) {
    final String c = card.replaceAll(' ', '').trim();
    final String p = '+380${phone.trim()}';
    final allCards = CardRepository().getAllCards();

    try {
      return allCards.firstWhere((a) => a.cardNumber == c && a.phone == p);
    } catch (e) {
      return null;
    }
  }

  Future<void> _sendCode() async {
    if (_cardController.text.replaceAll(' ', '').length < 16) {
      ATMService.showError(context, 'Номер картки має містити 16 цифр');
      return;
    }
    if (_phoneController.text.length < 9) {
      ATMService.showError(context, 'Введіть коректний номер телефону');
      return;
    }

    final card = _cardController.text.trim();
    final phone = _phoneController.text.trim();
    final found = _findAccountByCardAndPhone(card, phone);

    if (found == null) {
      ATMService.showError(context, 'Картка з таким номером та телефоном не знайдена');
      return;
    }

    setState(() {
      _matchedAccount = found;
      _isSending = true;
    });

    await Future.delayed(const Duration(seconds: 2));
    final randomCode = Random().nextInt(9000) + 1000;
    
    setState(() {
      _generatedCode = randomCode.toString();
      _codeController.text = _generatedCode!;
      _isSending = false;
    });
    ATMService.showSuccess(context, 'Код отримано (імітація SMS)');
  }

  void _confirmCode() {
    if (_codeController.text != _generatedCode) {
      ATMService.showError(context, 'Невірний код підтвердження');
      return;
    }
    _showBalanceDialog(_matchedAccount!);
  }

  void _loginWithPin() {
    final card = _cardController.text.replaceAll(' ', '').trim();
    final pin = _pinController.text.trim();
    
    if (card.length < 16 || pin.length < 4) {
      ATMService.showError(context, 'Заповніть всі поля коректно');
      return;
    }

    final allCards = CardRepository().getAllCards();

    try {
      final found = allCards.firstWhere((a) => a.cardNumber == card && a.pin == pin);
      _showBalanceDialog(found);
    } catch (e) {
      ATMService.showError(context, 'Невірна картка або PIN-код');
    }
  }

  void _showBalanceDialog(BankAccount account) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.green),
            SizedBox(width: 10),
            Text('Баланс рахунку'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Власник: ${account.fullName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Картка: **** **** **** ${account.cardNumber.substring(12)}'),
            const SizedBox(height: 10),
            Text(
              '${account.balance.toStringAsFixed(2)} ₴',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Зрозуміло', style: TextStyle(color: Colors.green, fontSize: 16)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Перевірка балансу'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade700, Colors.white],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Перемикач методу входу
                  SegmentedButton<LoginMethod>(
                    segments: const [
                      ButtonSegment(value: LoginMethod.cardPhone, label: Text('SMS-код'), icon: Icon(Icons.sms)),
                      ButtonSegment(value: LoginMethod.pin, label: Text('PIN-код'), icon: Icon(Icons.password)),
                    ],
                    selected: {_loginMethod},
                    onSelectionChanged: (Set<LoginMethod> newSelection) {
                      setState(() {
                        _loginMethod = newSelection.first;
                        _generatedCode = null;
                        _codeController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 25),

                  // Поле Номер картки
                 TextField(
                    controller: _cardController,
                    keyboardType: TextInputType.number,
                    // 16 цифр + 3 пробіли = 19 символів максимум
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(19), 
                    ],
                    onChanged: (value) {
                      final formatted = _formatCardNumber(value);
                      // Оновлюємо значення тільки якщо воно відрізняється від поточного
                      if (formatted != value) {
                        _cardController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      }
                      setState(() {}); // Для оновлення лічильників, якщо вони є
                    },
                    decoration: InputDecoration(
                      labelText: 'Номер картки',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      hintText: "0000 0000 0000 0000",
                      // Можна додати лічильник для візуального контролю
                      counterText: "${_cardController.text.replaceAll(' ', '').length}/16",
                    ),
                  ),
                  const SizedBox(height: 15),

                  if (_loginMethod == LoginMethod.cardPhone) ...[
                    // Логіка SMS
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 9,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Номер телефону',
                        prefixText: '+380 ',
                        prefixIcon: const Icon(Icons.phone_android),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        counterText: "",
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendCode,
                        icon: _isSending 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                        label: Text(_isSending ? 'Надсилаємо...' : 'Отримати SMS-код'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _codeController,
                      readOnly: _generatedCode == null,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Код підтвердження',
                        hintText: "****",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _generatedCode != null ? _confirmCode : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('ПЕРЕВІРИТИ БАЛАНС', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    // Логіка PIN
                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 10),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Введіть PIN-код',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        counterText: "",
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _loginWithPin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('УВІЙТИ ТА ПОКАЗАТИ БАЛАНС', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}