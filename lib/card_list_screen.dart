import 'dart:math';
import 'package:atm_project_unic/card_repository.dart';
import 'package:atm_project_unic/database.dart';
import 'package:atm_project_unic/create_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    _refreshCards();
  }

  void _refreshCards() {
    setState(() {
      // Використовуємо Singleton репозиторій. 
      // Переконайтеся, що у вашому CardRepository є метод getAllCards() або замініть на getAll()
      cards = CardRepository().getAllCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Ваші картки'),
        centerTitle: true,
      ),
      body: cards.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return BankCardWidget(
                  card: cards[index],
                  onDelete: () async {
                    await CardRepository().removeByIdNumber(cards[index].idNumber);
                    _refreshCards();
                  },
                ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateCardScreen()),
        ).then((_) => _refreshCards()),
        label: const Text('Додати картку'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Список порожній",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ОКРЕМИЙ ВІДЖЕТ КАРТКИ ДЛЯ ЛОГІКИ ПЕРЕВОРОТУ ТА ВІДОБРАЖЕННЯ
class BankCardWidget extends StatefulWidget {
  final BankAccount card;
  final VoidCallback onDelete;

  const BankCardWidget({super.key, required this.card, required this.onDelete});

  @override
  State<BankCardWidget> createState() => _BankCardWidgetState();
}

class _BankCardWidgetState extends State<BankCardWidget> {
  bool _isBackVisible = false;      // Чи бачимо задню сторону
  bool _showFullNumber = false;    // Чи бачимо повний номер
  bool _showCVV = false;           // Чи бачимо CVV

  void _toggleFlip() {
    setState(() {
      _isBackVisible = !_isBackVisible;
      _showCVV = false; // Приховуємо CVV при кожному перевороті назад/вперед
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: _isBackVisible ? 180 : 0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutBack,
      builder: (context, double value, child) {
        final isBack = value >= 90;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // Ефект перспективи
            ..rotateY(value * pi / 180),
          child: isBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi), // Щоб текст не був дзеркальним
                  child: _buildBackSide(),
                )
              : _buildFrontSide(),
        );
      },
    );
  }

  // ПЕРЕДНЯ СТОРОНА
  Widget _buildFrontSide() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.nfc, color: Colors.white70, size: 30),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.white),
                onPressed: () => _showDeleteDialog(),
              ),
            ],
          ),
          const Icon(Icons.memory, color: Colors.amber, size: 40),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _showFullNumber 
                              ? _formatCardNumber(widget.card.cardNumber)
                              : "**** **** **** ${widget.card.cardNumber.substring(widget.card.cardNumber.length - 4)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_showFullNumber ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 20),
                      onPressed: () => setState(() => _showFullNumber = !_showFullNumber),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.card.fullName.toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_android, color: Colors.amberAccent),
                      onPressed: _toggleFlip,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ЗАДНЯ СТОРОНА
  Widget _buildBackSide() {
    return _cardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Container(
            height: 45,
            width: double.infinity,
            color: Colors.black.withOpacity(0.8),
          ), // Магнітна стрічка
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 160,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 10),
                child: const Text("TretyakICT23Б", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CVV", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text(
                        _showCVV ? widget.card.cvv : "***",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(_showCVV ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 18),
                        onPressed: () => setState(() => _showCVV = !_showCVV),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Баланс: ${widget.card.balance.toStringAsFixed(2)} ₴",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.flip_camera_android, color: Colors.amberAccent),
                onPressed: _toggleFlip,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 220, // Фіксована висота для стабільності
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: child,
      ),
    );
  }

  String _formatCardNumber(String number) {
    return number.replaceAllMapped(RegExp(r".{4}"), (match) => "${match.group(0)} ");
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Видалити картку?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('НІ')),
          TextButton(onPressed: () { widget.onDelete(); Navigator.pop(ctx); }, child: const Text('ТАК')),
        ],
      ),
    );
  }
}