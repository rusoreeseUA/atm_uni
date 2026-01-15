import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:atm_project_unic/card_repository.dart';
import 'package:atm_project_unic/services/atm_services.dart';
import 'database.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _isAuthorized = false;
  bool _isWithdrawing = false;
  bool _showMoneyAnimation = false;
  BankAccount? _currentAccount;

  String _formatCardNumber(String input) {
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
    final card = _cardController.text.replaceAll(' ', '').trim();
    final pin = _pinController.text.trim();
    final allCards = CardRepository().getAllCards();

    try {
      final found = allCards.firstWhere((a) => a.cardNumber == card && a.pin == pin);
      setState(() {
        _currentAccount = found;
        _isAuthorized = true;
      });
      ATMService.showSuccess(context, 'Авторизація успішна');
    } catch (e) {
      ATMService.showError(context, 'Невірна картка або PIN');
    }
  }

  Future<void> _processWithdrawal() async {
    final double? amount = double.tryParse(_amountController.text);
    
    if (amount == null || amount <= 0) {
      ATMService.showError(context, 'Введіть коректну суму');
      return;
    }

    if (amount > _currentAccount!.balance) {
      ATMService.showError(context, 'Недостатньо коштів на рахунку');
      return;
    }

    setState(() => _isWithdrawing = true);
    await Future.delayed(2.seconds);

    final allCards = CardRepository().getAllCards();
    final index = allCards.indexWhere((a) => a.cardNumber == _currentAccount!.cardNumber);
    
    if (index != -1) {
      final updatedAccount = BankAccount(
        fullName: _currentAccount!.fullName,
        passportSerial: _currentAccount!.passportSerial,
        idNumber: _currentAccount!.idNumber,
        phone: _currentAccount!.phone,
        cardNumber: _currentAccount!.cardNumber,
        cvv: _currentAccount!.cvv,
        pin: _currentAccount!.pin,
        balance: _currentAccount!.balance - amount,
      );
      
      allCards[index] = updatedAccount;
      await CardRepository().saveAccounts(); 

    
      await CardRepository().addLog(TransactionLog(
        action: 'Зняття готівки',
        cardNumber: _currentAccount!.cardNumber,
        amount: amount,
        dateTime: DateTime.now(),
        details: 'Успішне зняття готівки',
      ));
      
      setState(() {
        _currentAccount = updatedAccount;
        _isWithdrawing = false;
        _showMoneyAnimation = true;
      });

      Future.delayed(4.seconds, () {
        if (mounted) setState(() => _showMoneyAnimation = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Зняття готівки')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _isAuthorized ? _buildWithdrawForm() : _buildAuthForm(),
          ),
          if (_showMoneyAnimation) _buildATMAnimation(),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return Column(
      children: [
        const Icon(Icons.lock_person, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        TextField(
          controller: _cardController,
          keyboardType: TextInputType.number,
          inputFormatters: [LengthLimitingTextInputFormatter(19)],
          onChanged: (v) => _cardController.value = TextEditingValue(
            text: _formatCardNumber(v),
            selection: TextSelection.collapsed(offset: _formatCardNumber(v).length),
          ),
          decoration: const InputDecoration(labelText: 'Номер картки', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [LengthLimitingTextInputFormatter(4)],
          decoration: const InputDecoration(labelText: 'PIN-код', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(onPressed: _login, child: const Text('УВІЙТИ')),
        ),
      ],
    );
  }

  Widget _buildWithdrawForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Вітаємо, ${_currentAccount!.fullName}!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text('Доступно: ${_currentAccount!.balance.toStringAsFixed(2)} ₴', style: const TextStyle(color: Colors.green, fontSize: 16)),
        const Divider(height: 40),
        const Text('Введіть суму для зняття:', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            suffixText: '₴',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isWithdrawing ? null : _processWithdrawal,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: _isWithdrawing 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('ЗНЯТИ ГРОШІ', style: TextStyle(fontSize: 18)),
          ),
        ),
      ],
    );
  }

  Widget _buildATMAnimation() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 250,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
              ),
            ),
            Stack(
              alignment: Alignment.topCenter,
              children: [
                for (int i = 0; i < 3; i++)
                  Container(
                    margin: EdgeInsets.only(top: i * 5),
                    width: 200,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade900, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.attach_money, size: 50, color: Colors.white),
                    ),
                  )
                  .animate()
                  .moveY(begin: -50, end: 100, duration: 1.seconds, delay: (i * 300).ms, curve: Curves.easeOut)
                  .fadeIn()
                  .then()
                  .shimmer(duration: 1.seconds),
              ],
            ),
            const SizedBox(height: 150),
            const Text(
              "Готівка видана!\nЗаберіть гроші",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 1.seconds).scale(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _showMoneyAnimation = false),
              child: const Text("ОК"),
            )
          ],
        ),
      ),
    );
  }
}