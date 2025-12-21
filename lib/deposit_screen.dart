import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:atm_project_unic/card_repository.dart';
import 'package:atm_project_unic/services/atm_services.dart';
import 'database.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final TextEditingController _cardController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  
  bool _isAuthorized = false;
  BankAccount? _currentAccount;
  double _depositedAmount = 0;
  bool _isInserting = false;
  String _currentBillAsset = 'assets/100uah.png';

  final Map<double, String> _billAssets = {
    100: 'assets/100uah.png',
    200: 'assets/200uah.png',
    500: 'assets/500uah.jpg',
  };

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

  void _insertBill(double value) async {
    if (_isInserting) return;

    setState(() {
      _isInserting = true;
      _currentBillAsset = _billAssets[value] ?? 'assets/100uah.png';
    });

    // Сповільнена анімація "затягування" (3 секунди)
    await Future.delayed(3000.ms);

    if (mounted) {
      setState(() {
        _depositedAmount += value;
        _isInserting = false;
      });
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _confirmDeposit() async {
    if (_depositedAmount <= 0) {
      ATMService.showError(context, 'Ви не вставили жодну купюру');
      return;
    }

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
        balance: _currentAccount!.balance + _depositedAmount,
      );

      allCards[index] = updatedAccount;
      await CardRepository().saveAccounts();

      await CardRepository().addLog(TransactionLog(
        action: 'Поповнення рахунку',
        cardNumber: _currentAccount!.cardNumber,
        amount: _depositedAmount,
        dateTime: DateTime.now(),
        details: 'Внесено готівку через приймач',
      ));

      ATMService.showSuccess(context, 'Рахунок поповнено на $_depositedAmount ₴');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Поповнення готівкою')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isAuthorized ? _buildDepositUI() : _buildAuthForm(),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Column(
      children: [
        const Icon(Icons.account_balance, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        TextField(
          controller: _cardController,
          keyboardType: TextInputType.number,
          inputFormatters: [LengthLimitingTextInputFormatter(19)],
          onChanged: (v) => _cardController.value = TextEditingValue(
            text: _formatCard(v),
            selection: TextSelection.collapsed(offset: _formatCard(v).length),
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
          child: ElevatedButton(onPressed: _login, child: const Text('ПІДТВЕРДИТИ')),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildDepositUI() {
    return Column(
      children: [
        Text(
          'СУМА: ${_depositedAmount.toStringAsFixed(0)} ₴',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green),
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
        
        const SizedBox(height: 20),
        
        // ПРИЙМАЧ БАНКОМАТА
        SizedBox(
          height: 250, 
          width: 300,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // 1. Панель банкомата (основа)
              Container(
                width: 260,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade300, Colors.grey.shade500],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade700, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("INSERT BILL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 8),
                    // Світловий індикатор прорізу
                    Container(
                      width: 190,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container()
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 1500.ms, color: Colors.greenAccent.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),

              // 2. Купюра, яка рухається (Тепер вона ОСТАННЯ в списку, щоб бути ЗВЕРХУ)
              if (_isInserting)
                Positioned(
                  top: 110, // Починаємо трохи нижче панелі
                  child: Image.asset(
                    _currentBillAsset,
                    width: 160,
                    height: 80,
                    fit: BoxFit.contain,
                  )
                  .animate()
                  // Плавний рух вгору до прорізу
                  .moveY(begin: 0, end: -75, duration: 3000.ms, curve: Curves.easeInOutSine)
                  // Ефект фізичного заходження (стискання по висоті в кінці)
                  .scaleY(begin: 1.0, end: 0.05, duration: 3000.ms, curve: Curves.easeInCirc)
                  // Зникнення при вході
                  .fadeOut(delay: 1500.ms, duration: 1000.ms),
                ),
            ],
          ),
        ),

        const Text("Оберіть номінал для поповнення:", style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 20),

        Wrap(
          spacing: 15,
          runSpacing: 15,
          alignment: WrapAlignment.center,
          children: [
            _buildBillBtn(100, 'assets/100uah.png'),
            _buildBillBtn(200, 'assets/200uah.png'),
            _buildBillBtn(500, 'assets/500uah.jpg'),
          ],
        ),

        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isInserting ? null : _confirmDeposit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('ЗАРАХУВАТИ НА КАРТКУ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildBillBtn(double value, String asset) {
    return GestureDetector(
      onTap: () => _insertBill(value),
      child: Container(
        width: 110,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(asset, fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(0.1)),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(6)),
                  child: Text("${value.toInt()} ₴", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -3, duration: 1500.ms),
    );
  }
}