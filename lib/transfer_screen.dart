import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:atm_project_unic/card_repository.dart';
import 'package:atm_project_unic/services/atm_services.dart';
import 'database.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final TextEditingController _senderCardController = TextEditingController();
  final TextEditingController _senderPinController = TextEditingController();
  final TextEditingController _recipientCardController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _isAuthorized = false;
  bool _isProcessing = false;
  BankAccount? _senderAccount;

  String _formatCard(String input) {
    String digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 16) digits = digits.substring(0, 16);
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i + 1) % 4 == 0 && i + 1 != digits.length) buffer.write(' ');
    }
    return buffer.toString();
  }

  void _login() {
    final card = _senderCardController.text.replaceAll(' ', '').trim();
    final pin = _senderPinController.text.trim();
    final allCards = CardRepository().getAllCards();

    try {
      final found = allCards.firstWhere((a) => a.cardNumber == card && a.pin == pin);
      setState(() {
        _senderAccount = found;
        _isAuthorized = true;
      });
      ATMService.showSuccess(context, 'Авторизація успішна');
    } catch (e) {
      ATMService.showError(context, 'Невірна картка або PIN відправника');
    }
  }

  Future<void> _processTransfer() async {
    final recipientRaw = _recipientCardController.text.replaceAll(' ', '').trim();
    final double? amount = double.tryParse(_amountController.text);

    if (recipientRaw.length < 16) {
      ATMService.showError(context, 'Введіть повний номер картки отримувача');
      return;
    }
    if (amount == null || amount <= 0) {
      ATMService.showError(context, 'Введіть коректну суму');
      return;
    }
    if (amount > _senderAccount!.balance) {
      ATMService.showError(context, 'Недостатньо коштів для переказу');
      return;
    }
    if (recipientRaw == _senderAccount!.cardNumber) {
      ATMService.showError(context, 'Не можна переказувати кошти самому собі');
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(2.seconds);

    final allCards = CardRepository().getAllCards();
    
    try {
      final recipientIndex = allCards.indexWhere((a) => a.cardNumber == recipientRaw);
      if (recipientIndex == -1) {
        throw 'Отримувача не знайдено в базі даних';
      }

      final senderIndex = allCards.indexWhere((a) => a.cardNumber == _senderAccount!.cardNumber);

      allCards[senderIndex] = _updateBalance(allCards[senderIndex], -amount);
      allCards[recipientIndex] = _updateBalance(allCards[recipientIndex], amount);

      await CardRepository().saveAccounts();

      // ДОДАВАННЯ ЛОГУ
      await CardRepository().addLog(TransactionLog(
        action: 'Переказ коштів',
        cardNumber: _senderAccount!.cardNumber,
        amount: amount,
        dateTime: DateTime.now(),
        details: 'Переказ на картку $recipientRaw',
      ));

      setState(() {
        _senderAccount = allCards[senderIndex];
        _isProcessing = false;
      });

      _showSuccessDialog(allCards[recipientIndex].fullName, amount);
    } catch (e) {
      setState(() => _isProcessing = false);
      ATMService.showError(context, e.toString());
    }
  }

  BankAccount _updateBalance(BankAccount acc, double change) {
    return BankAccount(
      fullName: acc.fullName,
      passportSerial: acc.passportSerial,
      idNumber: acc.idNumber,
      phone: acc.phone,
      cardNumber: acc.cardNumber,
      cvv: acc.cvv,
      pin: acc.pin,
      balance: acc.balance + change,
    );
  }

  void _showSuccessDialog(String recipientName, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(
          'Переказ на суму $amount ₴ успішно надіслано отримувачу $recipientName!',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')))
        ],
      ).animate().scale(curve: Curves.easeOutBack),
    );
    _recipientCardController.clear();
    _amountController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Переказ коштів')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isAuthorized ? _buildTransferForm() : _buildAuthForm(),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Column(
      children: [
        const Icon(Icons.swap_horizontal_circle, size: 80, color: Colors.blue),
        const SizedBox(height: 20),
        const Text('Для здійснення переказу увійдіть у свій аккаунт', textAlign: TextAlign.center),
        const SizedBox(height: 30),
        TextField(
          controller: _senderCardController,
          keyboardType: TextInputType.number,
          inputFormatters: [LengthLimitingTextInputFormatter(19)],
          onChanged: (v) => _senderCardController.value = TextEditingValue(
            text: _formatCard(v),
            selection: TextSelection.collapsed(offset: _formatCard(v).length),
          ),
          decoration: const InputDecoration(labelText: 'Ваша картка', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _senderPinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [LengthLimitingTextInputFormatter(4)],
          decoration: const InputDecoration(labelText: 'Ваш PIN', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(onPressed: _login, child: const Text('ПІДТВЕРДИТИ ОСОБУ')),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildTransferForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: Colors.blue.shade50,
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: Text(_senderAccount!.fullName),
            subtitle: Text('Ваш баланс: ${_senderAccount!.balance.toStringAsFixed(2)} ₴'),
          ),
        ),
        const SizedBox(height: 30),
        const Text('Дані отримувача:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _recipientCardController,
          keyboardType: TextInputType.number,
          inputFormatters: [LengthLimitingTextInputFormatter(19)],
          onChanged: (v) => _recipientCardController.value = TextEditingValue(
            text: _formatCard(v),
            selection: TextSelection.collapsed(offset: _formatCard(v).length),
          ),
          decoration: const InputDecoration(
            labelText: 'Картка отримувача',
            hintText: '0000 0000 0000 0000',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.credit_card),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            labelText: 'Сума переказу',
            suffixText: '₴',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.money),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processTransfer,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
            child: _isProcessing 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('ЗДІЙСНИТИ ПЕРЕКАЗ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ).animate().slideX(begin: 0.2, end: 0);
  }
}