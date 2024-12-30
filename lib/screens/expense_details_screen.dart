// lib/screens/expense_details_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/expense.dart';
import '../models/dynamic_field.dart';
import 'dart:convert';

class ExpenseDetailsScreen extends StatefulWidget {
  final int expenseId;

  const ExpenseDetailsScreen({required this.expenseId, Key? key}) : super(key: key);

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  final DatabaseService _db = DatabaseService();
  Expense? _expense;
  List<DynamicField> _dynamicFields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenseDetails();
  }

  Future<void> _loadExpenseDetails() async {
    final expense = await _db.getExpenseById(widget.expenseId);
    if (expense != null) {
      final dynamicFields = await _db.getDynamicFields('expenses');
      setState(() {
        _expense = expense;
        _dynamicFields = dynamicFields;
        _isLoading = false;
      });
    } else {
      setState(() {
        _expense = null;
        _dynamicFields = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Расход не найден')),
        body: const Center(child: Text('Данный расход не найден')),
      );
    }

    // Предполагаем, что _expense.dynamicFields уже Map<String, dynamic>
    final dynamicValues = _expense!.dynamicFields ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Детали Расхода')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Карточка информации
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Расход №${_expense!.id}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Товар ID: ${_expense!.productId}',
                      style: const TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Количество: ${_expense!.quantity}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Дата: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(_expense!.date))}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Divider(height: 20),
                    if (_expense!.categoryId != null)
                      Text('Категория ID: ${_expense!.categoryId}', style: const TextStyle(fontSize: 16)),
                    if (_expense!.typeId != null)
                      Text('Тип ID: ${_expense!.typeId}', style: const TextStyle(fontSize: 16)),
                    if (_expense!.techId != null)
                      Text('Техника ID: ${_expense!.techId}', style: const TextStyle(fontSize: 16)),
                    if (_expense!.barcode != null)
                      Text('Штрих-код: ${_expense!.barcode}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Динамические поля
            if (_dynamicFields.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Дополнительные Поля:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._dynamicFields.map((field) {
                    final value = dynamicValues[field.fieldName] ?? 'Не указано';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('${field.fieldLabel}: $value', style: const TextStyle(fontSize: 16)),
                    );
                  }).toList(),
                ],
              )
            else
              const SizedBox(),
          ],
        ),
      ),
    );
  }
}