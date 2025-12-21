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
  String _currentBillAsset = 'assets/100uah.png'; // Дефолтне зображення

  // Мапінг номіналів до ваших зображень
  final Map<double, String> _billAssets = {
    100: 'assets/100uah.png',
    200: 'assets/200uah.png',
    500: 'assets/500uah.jpg',
    1000: 'assets/1000uah.png', // Використаємо ngl для великого номіналу
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
      _currentBillAsset = _billAssets[value]!;
    });

    // Час анімації всмоктування
    await Future.delayed(1200.ms);

    setState(() {
      _depositedAmount += value;
      _isInserting = false;
    });
    
    HapticFeedback.heavyImpact(); 
  }

  Future<void> _confirmDeposit() async {
    if (_depositedAmount <= 0) {
      ATMService.showError(context, 'Ви не вставили жодної купюри');
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
        ).animate(target: _depositedAmount > 0 ? 1 : 0).scale(duration: 300.ms).then().shimmer(),
        
        const SizedBox(height: 30),
        
        // Візуалізація банкомата з ефектом всмоктування
        SizedBox(
          height: 300,
          width: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Внутрішня частина (темрява за прорізом)
              Positioned(
                top: 80,
                child: Container(
                  width: 220,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // 2. Купюра, яка рухається
              if (_isInserting)
                Positioned(
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.asset(
                      _currentBillAsset,
                      width: 180,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  )
                  .animate()
                  .moveY(begin: 150, end: -40, duration: 1200.ms, curve: Curves.easeInOutExpo)
                  .scale(begin: const Offset(1, 1), end: const Offset(0.8, 0.5), duration: 1200.ms)
                  .fadeOut(delay: 800.ms),
                ),

              // 3. Передня панель банкомата (над купюрою)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 260,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade600, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("INSERT CASH", style: TextStyle(letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      // Сам проріз
                      Container(
                        width: 200,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.greenAccent.withOpacity(0.3)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Text("Оберіть купюру:", style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 20),

        // Кнопки-купюри
        Wrap(
          spacing: 15,
          runSpacing: 15,
          alignment: WrapAlignment.center,
          children: [
            _buildBillBtn(100, 'assets/100uah.png'),
            _buildBillBtn(200, 'assets/200uah.png'),
            _buildBillBtn(500, 'assets/500uah.jpg'),
            _buildBillBtn(1000, 'assets/1000uah.png'),
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
            child: const Text('ЗАРАХУВАТИ КОШТИ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildBillBtn(double value, String asset) {
    return GestureDetector(
      onTap: () => _insertBill(value),
      child: Container(
        width: 100,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            children: [
              Image.asset(asset, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
              Container(color: Colors.black.withOpacity(0.2)),
              Center(child: Text("${value.toInt()} ₴", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -3, duration: 1.seconds),
    );
  }
}