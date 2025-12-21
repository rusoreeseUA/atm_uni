import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';

class CardRepository {
  static const String _storageKey = "bank_accounts";
  static const String _logsKey = "transaction_logs";
  
  // Singleton патерн (забезпечує доступ до одного об'єкта з усієї програми)
  static final CardRepository _instance = CardRepository._internal();
  factory CardRepository() => _instance;
  CardRepository._internal();

  List<BankAccount> _accounts = [];
  List<TransactionLog> _logs = [];

  // Завантаження даних з локального сховища
  Future<void> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Завантаження списку акаунтів/карток
    final accountsJson = prefs.getString(_storageKey);
    if (accountsJson != null) {
      final List<dynamic> data = jsonDecode(accountsJson);
      _accounts = data.map((e) => BankAccount.fromJson(e)).toList();
    } else {
      // БЕЗ mockAccounts: якщо даних немає, список залишається порожнім
      _accounts = [];
    }

    // 2. Завантаження історії операцій (логів)
    final logsJson = prefs.getString(_logsKey);
    if (logsJson != null) {
      final List<dynamic> data = jsonDecode(logsJson);
      _logs = data.map((e) => TransactionLog.fromJson(e)).toList();
    } else {
      _logs = [];
    }
  }

  // Збереження списку карток у пам'ять телефону
  Future<void> saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_accounts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  // Збереження списку логів у пам'ять телефону
  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_logs.map((e) => e.toJson()).toList());
    await prefs.setString(_logsKey, jsonString);
  }

  // --- Методи для роботи з картками ---

  /// Повертає список усіх наявних карток
  List<BankAccount> getAllCards() => _accounts;

  /// Додає нову картку та зберігає зміни
  Future<void> addCard(BankAccount account) async {
    _accounts.add(account);
    await saveAccounts();
  }

  /// Видаляє картку за ІПН та зберігає зміни
  Future<bool> removeByIdNumber(String idNumber) async {
    final index = _accounts.indexWhere((a) => a.idNumber == idNumber);
    if (index != -1) {
      _accounts.removeAt(index);
      await saveAccounts();
      return true;
    }
    return false;
  }

  // --- Методи для роботи з логами ---

  /// Повертає список усіх записів історії
  List<TransactionLog> getAllLogs() => _logs;

  /// Додає новий запис до історії та зберігає його
  Future<void> addLog(TransactionLog log) async {
    _logs.add(log);
    await _saveLogs();
  }
}