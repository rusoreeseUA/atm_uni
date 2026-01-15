import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';

class CardRepository {
  static const String _storageKey = "bank_accounts";
  static const String _logsKey = "transaction_logs";
  
  static final CardRepository _instance = CardRepository._internal();
  factory CardRepository() => _instance;
  CardRepository._internal();

  List<BankAccount> _accounts = [];
  List<TransactionLog> _logs = [];

    Future<void> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    

    final accountsJson = prefs.getString(_storageKey);
    if (accountsJson != null) {
      final List<dynamic> data = jsonDecode(accountsJson);
      _accounts = data.map((e) => BankAccount.fromJson(e)).toList();
    } else {
    
      _accounts = [];
    }

  
    final logsJson = prefs.getString(_logsKey);
    if (logsJson != null) {
      final List<dynamic> data = jsonDecode(logsJson);
      _logs = data.map((e) => TransactionLog.fromJson(e)).toList();
    } else {
      _logs = [];
    }
  }


  Future<void> saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_accounts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_logs.map((e) => e.toJson()).toList());
    await prefs.setString(_logsKey, jsonString);
  }

  List<BankAccount> getAllCards() => _accounts;

  Future<void> addCard(BankAccount account) async {
    _accounts.add(account);
    await saveAccounts();
  }

  Future<bool> removeByIdNumber(String idNumber) async {
    final index = _accounts.indexWhere((a) => a.idNumber == idNumber);
    if (index != -1) {
      _accounts.removeAt(index);
      await saveAccounts();
      return true;
    }
    return false;
  }


  List<TransactionLog> getAllLogs() => _logs;

  Future<void> addLog(TransactionLog log) async {
    _logs.add(log);
    await _saveLogs();
  }
}