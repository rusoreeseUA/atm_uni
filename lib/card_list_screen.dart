// card_list_screen.dart
import 'package:atm_project_unic/card_repository.dart';
import 'package:atm_project_unic/database.dart';
import 'package:flutter/material.dart';

class CardListScreen extends StatefulWidget {
  const CardListScreen({super.key});

  @override
  _CardListScreenState createState() => _CardListScreenState();
}

class _CardListScreenState extends State<CardListScreen> {
  List<BankAccount> cards = [];

  @override
  void initState() {
    super.initState();
    cards = CardRepository.getAllCards();
  }

  void _refreshCards() {
    setState(() {
      cards = CardRepository.getAllCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Список карток')),
      body: ListView.builder(
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return ListTile(
            title: Text(card.fullName),
            subtitle: Text('ІПН: ${card.idNumber}  |  Номер картки: ${card.cardNumber}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Видаляємо картку за ID
                CardRepository.removeByIdNumber(card.idNumber);
                _refreshCards(); // оновлюємо віджет
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Картку з ІПН ${card.idNumber} видалено'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
