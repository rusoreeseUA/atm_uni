// balance_screen.dart
import 'dart:math';
import 'package:atm_project_unic/services/atm_services.dart';
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
  String _formatCardNumber(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i + 1 != digits.length) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  // Нормалізація телефону
  String _normalizePhone(String input) {
    String digits = input.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length == 9) return '+380$digits';
    if (digits.length == 10 && digits.startsWith('0')) return '+38$digits';
    if (digits.length == 12 && digits.startsWith('380')) return '+$digits';
    if (input.trim().startsWith('+')) return input.trim();
    if (digits.isNotEmpty) return '+$digits';

    return input;
  }

  BankAccount? _findAccountByCardAndPhone(String card, String phone) {
    final String c = card.replaceAll(' ', '').trim();
    final String p = _normalizePhone(phone);

    try {
      return mockAccounts.firstWhere(
        (a) => a.cardNumber == c && a.phone == p,
      );
    } catch (e) {
      return null;
    }
  }

  // --- Валідатори ---
  int get _cardDigitsCount => _cardController.text.replaceAll(' ', '').length;
  int get _phoneDigitsCount =>
      _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').length;
  int get _pinDigitsCount => _pinController.text.length;

  bool _validateCardForAction() {
    if (_cardDigitsCount < 16) {
      ATMService.showInfo(context, 'Номер картки має містити 16 цифр.');
      return false;
    }
    return true;
  }

  bool _validatePhoneForSend() {
    if (_phoneDigitsCount < 9) {
      ATMService.showInfo(context, 'Номер телефону має містити 9 цифр.');
      return false;
    }
    return true;
  }

  bool _validatePinForLogin() {
    if (_pinDigitsCount < 4) {
      ATMService.showInfo(context, 'PIN має містити 4 цифри.');
      return false;
    }
    return true;
  }
  // --- /Валідатори ---

  Future<void> _sendCode() async {
    // валідуємо при кожному натисканні кнопки
    if (!_validateCardForAction()) return;
    if (!_validatePhoneForSend()) return;

    final card = _cardController.text.trim();
    final phone = _phoneController.text.trim();

    final found = _findAccountByCardAndPhone(card, phone);

    if (found == null) {
      ATMService.showError(
        context,
        'Картка з таким номером та телефоном не знайдена в системі.',
      );
      return;
    }

    setState(() {
      _matchedAccount = found;
      _isSending = true;
      _generatedCode = null;
      _codeController.text = '';
    });

    await Future.delayed(const Duration(seconds: 5));

    final randomCode = Random().nextInt(9000) + 1000;
    setState(() {
      _generatedCode = randomCode.toString();
      _codeController.text = _generatedCode!;
      _isSending = false;
    });

    ATMService.showSuccess(context, 'Код отримано (імітація SMS).');
  }

  void _confirmCode() {
    if (_generatedCode == null) {
      ATMService.showInfo(context, 'Спочатку надішліть код.');
      return;
    }

    if (_codeController.text.trim() != _generatedCode) {
      ATMService.showError(context, 'Невірний код.');
      return;
    }

    if (_matchedAccount == null) {
      ATMService.showError(context, 'Внутрішня помилка: аккаунт не знайдено.');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Баланс рахунку'),
        content: Text(
          'Картка: ${_matchedAccount!.cardNumber}\n'
          'Власник: ${_matchedAccount!.fullName}\n'
          'Баланс: ${_matchedAccount!.balance.toStringAsFixed(2)} ₴',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрити'),
          )
        ],
      ),
    );
  }

  void _loginWithPin() {
    // валідуємо при кожному натисканні кнопки
    if (!_validateCardForAction()) return;
    if (!_validatePinForLogin()) return;

    final card = _cardController.text.replaceAll(' ', '').trim();
    final pin = _pinController.text.trim();

    BankAccount? found;
    try {
      found = mockAccounts.firstWhere(
        (a) => a.cardNumber == card,
      );
    } catch (e) {
      found = null;
    }

    if (found == null) {
      ATMService.showError(context, 'Картка не знайдена.');
      return;
    }

    if (found.pin != pin) {
      ATMService.showError(context, 'Невірний PIN.');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Баланс рахунку'),
        content: Text(
          'Картка: ${found?.cardNumber}\n'
          'Власник: ${found?.fullName}\n'
          'Баланс: ${found?.balance.toStringAsFixed(2)} ₴',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрити'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cardController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardDigitsCount = _cardController.text.replaceAll(' ', '').length;
    final pinDigitsCount = _pinController.text.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Перевірка балансу'),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioListTile<LoginMethod>(
                    title: const Text('Картка + Телефон'),
                    value: LoginMethod.cardPhone,
                    groupValue: _loginMethod,
                    onChanged: (v) {
                      setState(() {
                        _loginMethod = v!;
                        _generatedCode = null;
                        _codeController.clear();
                        _matchedAccount = null;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<LoginMethod>(
                    title: const Text('Вхід з PIN'),
                    value: LoginMethod.pin,
                    groupValue: _loginMethod,
                    onChanged: (v) {
                      setState(() {
                        _loginMethod = v!;
                        _generatedCode = null;
                        _codeController.clear();
                        _matchedAccount = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cardController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              onChanged: (val) {
                final formatted = _formatCardNumber(val);
                if (formatted != val) {
                  _cardController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Номер картки',
                border: const OutlineInputBorder(),
                suffixText: '$cardDigitsCount/16',
              ),
            ),
            const SizedBox(height: 12),
            if (_loginMethod == LoginMethod.cardPhone) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Номер телефону',
                  prefixText: '+380 ',
                  hintText: 'XX XXX XXXX',
                  suffixText: '${_phoneController.text.length}/9',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: (_isSending) ? null : _sendCode,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.black38),
                label: Text(
                  _isSending ? 'Надсилається...' : 'Надіслати код',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSending ? Colors.grey : Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Код із SMS',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: (_generatedCode != null && !_isSending)
                    ? _confirmCode
                    : null,
                child: const Text(
                  'Підтвердити код і подивитись баланс',
                  style: TextStyle(
                    color: Color.fromARGB(255, 75, 75, 75),
                  ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'PIN-код',
                  border: const OutlineInputBorder(),
                  suffixText: '$pinDigitsCount/4',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loginWithPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                ),
                child: const Text(
                  'Увійти по PIN і подивитись баланс',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
