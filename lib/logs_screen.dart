import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:atm_project_unic/card_repository.dart';
import 'package:atm_project_unic/database.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _selectedFilter = 'Всі';
  final List<String> _filters = ['Всі', 'Зняття', 'Переказ', 'Поповнення', 'Баланс', 'Створення'];

  // Допоміжна функція для маскування номера картки (**** 1234)
  String _maskCard(String card) {
    if (card.length < 4) return card;
    return "**** ${card.substring(card.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    // Отримуємо логи та сортуємо їх (найсвіжіші зверху)
    List<TransactionLog> allLogs = CardRepository().getAllLogs();
    allLogs.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    // Фільтрація
    List<TransactionLog> filteredLogs = _selectedFilter == 'Всі'
        ? allLogs
        : allLogs.where((log) => log.action.contains(_selectedFilter)).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Історія операцій'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Рядок з фільтрами
          Container(
            height: 70,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Colors.green.shade600,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              },
            ),
          ),
          
          // Список логів
          Expanded(
            child: filteredLogs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      return _buildLogItem(filteredLogs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Операцій не знайдено", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildLogItem(TransactionLog log) {
    Color iconColor;
    IconData iconData;
    bool isTransfer = log.action.contains('Переказ');

    // Визначення стилю залежно від типу операції
    if (log.action.contains('Зняття')) {
      iconColor = Colors.orange.shade700;
      iconData = Icons.money_off_rounded;
    } else if (isTransfer) {
      iconColor = Colors.blue.shade700;
      iconData = Icons.swap_horiz_rounded;
    } else if (log.action.contains('Поповнення')) {
      iconColor = Colors.teal.shade700;
      iconData = Icons.add_circle_outline_rounded;
    } else if (log.action.contains('Створення')) {
      iconColor = Colors.green.shade700;
      iconData = Icons.add_card_rounded;
    } else {
      iconColor = Colors.grey.shade700;
      iconData = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(iconData, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.action,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      // Відображення деталей картки
                      if (isTransfer)
                        Row(
                          children: [
                            Text(_maskCard(log.cardNumber), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                            const Icon(Icons.arrow_right_alt, size: 18, color: Colors.grey),
                            // Спроба дістати номер отримувача з тексту details
                            Text(
                              _maskCard(log.details.replaceAll(RegExp(r'[^0-9]'), '')),
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      else
                        Text(
                          "Картка: ${_maskCard(log.cardNumber)}",
                          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd.MM.yyyy • HH:mm').format(log.dateTime),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                if (log.amount != null)
                  Text(
                    "${log.action.contains('Зняття') || isTransfer ? '-' : '+'}${log.amount!.toStringAsFixed(0)} ₴",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: log.action.contains('Зняття') || isTransfer 
                          ? Colors.red.shade700 
                          : Colors.green.shade700,
                    ),
                  ),
              ],
            ),
            const Divider(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                log.details,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}