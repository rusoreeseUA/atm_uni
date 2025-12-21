import 'package:atm_project_unic/card_list_screen.dart';
import 'package:atm_project_unic/create_card_screen.dart';
import 'package:atm_project_unic/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
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
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        title: const Text(
          "ATM Головне Меню",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
            _buildATMButton(context, "Список карток", Icons.view_list), // 🔹 нова кнопка
            _buildATMButton(context, "Вихід", Icons.exit_to_app),
          ],
        ),
      ),
    );
  }

  Widget _buildATMButton(BuildContext context, String label, IconData icon) {
    return ElevatedButton(
      // ... стиль кнопки ...
      onPressed: () {
        if (label == "Баланс") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BalanceScreen()),
          );
        } 
        else if (label == "Список карток") {
          // Перехід на екран зі списком карток
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CardListScreen()),
          );
        }
        else if (label == "Створити картку") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateCardScreen()),
          );
        } 
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Натиснуто: $label")),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}