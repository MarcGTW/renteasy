
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class BookingScreen extends StatefulWidget {
  final String propertyTitle;

  const BookingScreen({
    super.key,
    required this.propertyTitle,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime? _selectedDateTime;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );

    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _selectedDateTime = selected;
      _dateController.text =
          '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year} '
          '${time.format(context)}';
    });

    _formKey.currentState?.validate();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);

    context.pop();

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Заявка на просмотр успешно отправлена!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запись на просмотр'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Объект: ${widget.propertyTitle}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Ваше имя',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите ваше имя';
                }
                if (value.trim().length < 2) {
                  return 'Имя должно содержать минимум 2 символа';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: const InputDecoration(
                labelText: 'Номер телефона',
                hintText: '37369123456',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите номер телефона';
                }
                if (!RegExp(r'^373\d{8}$').hasMatch(value)) {
                  return 'Введите номер в формате 373XXXXXXXX';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: _selectDateTime,
              decoration: const InputDecoration(
                labelText: 'Дата и время просмотра',
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
                border: OutlineInputBorder(),
              ),
              validator: (_) {
                if (_selectedDateTime == null) {
                  return 'Выберите дату и время';
                }
                if (!_selectedDateTime!.isAfter(DateTime.now())) {
                  return 'Выберите будущую дату и время';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Отправить заявку'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
