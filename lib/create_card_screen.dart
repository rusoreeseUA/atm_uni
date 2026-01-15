import 'package:atm_project_unic/card_repository.dart';
import 'package:atm_project_unic/services/atm_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database.dart';

class CreateCardScreen extends StatefulWidget {
  const CreateCardScreen({super.key});

  @override
  State<CreateCardScreen> createState() => _CreateCardScreenState();
}

class _CreateCardScreenState extends State<CreateCardScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passportSerialController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  void _saveCard() {
    if (_formKey.currentState!.validate()) {
      final newAccount = BankAccount(
        fullName: _fullNameController.text.trim(),
        passportSerial: _passportSerialController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        phone: '+380${_phoneController.text.trim()}',
        cardNumber: _cardNumberController.text.trim().replaceAll(' ', ''),
        cvv: _cvvController.text.trim(),
        pin: _pinController.text.trim(),
        balance: 100.0,
      );

      CardRepository().addCard(newAccount).then((_) async {
      
        await CardRepository().addLog(TransactionLog(
          action: 'Створення картки',
          cardNumber: newAccount.cardNumber,
          dateTime: DateTime.now(),
          details: 'Створено нову картку для ${newAccount.fullName}',
        ));

        ATMService.showSuccess(context, "Картку успішно створено та збережено");
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _passportSerialController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cvvController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Створити картку"),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildTextField(
                  controller: _fullNameController,
                  label: "ПІБ",
                  maxLength: 40,
                  validator: (value) =>
                      value == null || value.isEmpty ? "Введіть прізвище та ім’я" : null,
                  topPadding: 4,
                ),
                _buildTextField(
                  controller: _passportSerialController,
                  label: "Серія паспорта",
                  maxLength: 6,
                  validator: (value) =>
                      value == null || value.length != 6 ? "Серія паспорта має містити 6 символів" : null,
                ),
                _buildTextField(
                  controller: _idNumberController,
                  label: "Ідентифікаційний номер",
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value == null || value.length != 8 ? "Невірний ІПН" : null,
                ),
                _buildTextField(
                  controller: _phoneController,
                  label: "Телефон",
                  keyboardType: TextInputType.phone,
                  prefixText: '+380',
                  maxLength: 9,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value == null || value.length != 9 ? "Невірний номер телефону" : null,
                ),
                _buildTextField(
                  controller: _cardNumberController,
                  label: "Номер картки",
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value == null || value.length != 16 ? "Номер картки має містити 16 цифр" : null,
                ),
                _buildTextField(
                  controller: _cvvController,
                  label: "CVV",
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value == null || value.length != 3 ? "CVV має містити 3 цифри" : null,
                ),
                _buildTextField(
                  controller: _pinController,
                  label: "PIN",
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value == null || value.length != 4 ? "PIN має містити 4 цифри" : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveCard,
                  child: const Text(
                    "Створити картку",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? prefixText,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    double topPadding = 0.0,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.0, top: topPadding),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      ),
    );
  }
}