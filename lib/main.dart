import 'package:atm_project_unic/card_list_screen.dart';
import 'package:atm_project_unic/create_card_screen.dart';
import 'package:atm_project_unic/deposit_screen.dart';
import 'package:atm_project_unic/intro_screen.dart'; // Імпортуємо IntroScreen
import 'package:atm_project_unic/balance_screen.dart';
import 'package:atm_project_unic/card_repository.dart';
import 'package:atm_project_unic/logs_screen.dart';
import 'package:atm_project_unic/transfer_screen.dart';
import 'package:atm_project_unic/withdrawal_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ініціалізація бази даних (завантажується швидко, доки йде інтро)
  await CardRepository().loadAccounts(); 
  runApp(const ATMApp());
}

class ATMApp extends StatelessWidget {
  const ATMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ATM Project',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        // Налаштуємо стиль AppBar глобально, щоб він виглядав гарно всюди
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white, // Колір тексту та іконок
          centerTitle: true,
          elevation: 4,
          titleTextStyle: const TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.bold, 
            color: Colors.white
          ),
        ),
        useMaterial3: true,
      ),
      // ЗМІНЕНО: Тепер стартовий екран - це IntroScreen
      home: const IntroScreen(),
    );
  }
}

// MainMenuScreen залишається без змін, але ми його експортуємо для IntroScreen
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar тепер бере стиль з глобальної теми, заданої вище
      appBar: AppBar(
        title: const Text("ATM Головне Меню"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildATMButton(context, "Баланс", Icons.account_balance_wallet),
            _buildATMButton(context, "Зняття", Icons.money_off),
            _buildATMButton(context, "Поповнення", Icons.attach_money),
            _buildATMButton(context, "Переказ", Icons.swap_horiz),
            _buildATMButton(context, "Логи", Icons.list_alt),
            _buildATMButton(context, "Створити картку", Icons.credit_card),
            _buildATMButton(context, "Список карток", Icons.view_list),
            _buildATMButton(context, "Вихід", Icons.exit_to_app),
          ],
        ),
      ),
    );
  }

  Widget _buildATMButton(BuildContext context, String label, IconData icon) {
    // Кольорова схема для кнопок
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Фон кнопки білий
        foregroundColor: primaryColor, // Іконка та текст зелені
        elevation: 5, // Тінь
        shadowColor: Colors.green.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Заокруглені кути
          side: BorderSide(color: primaryColor.withOpacity(0.5), width: 1)
        ),
      ),
      onPressed: () {
        if (label == "Баланс") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BalanceScreen()));
        } else if (label == "Список карток") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CardListScreen()));
        } else if (label == "Створити картку") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateCardScreen()));
        } 
        else if (label == "Зняття") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen()));
        }
         else if (label == "Переказ") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen()));
        }
         else if (label == "Логи") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LogsScreen()));
        }
         else if (label == "Поповнення") {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DepositScreen()));
        }
        else if (label == "Вихід") {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Сесію завершено")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Функція '$label' в розробці")));
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}