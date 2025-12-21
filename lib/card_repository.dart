import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database.dart';

class CardRepository {
  static const String _storageKey = "bank_accounts";

  List<BankAccount> _accounts = [];

  Future<void> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> data = jsonDecode(jsonString);
      _accounts = data.map((e) => BankAccount.fromJson(e)).toList();
    } else {
      // якщо ще нічого не збережено -> завантажуємо мокові
      _accounts = mockAccounts;
      await saveAccounts();
    }
  }

  Future<void> saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        jsonEncode(_accounts.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  List<BankAccount> getAll() => _accounts;

  Future<void> add(BankAccount account) async {
    _accounts.add(account);
    await saveAccounts();
  }

  Future<bool> removeByIdNumber(String idNumber) async {
    final removed = _accounts.removeWhere((a) => a.idNumber == idNumber) > 0;
    if (removed) await saveAccounts();
    return removed;
  }
}
