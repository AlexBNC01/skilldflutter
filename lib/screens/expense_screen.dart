// expense screen 
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/expense.dart';
import '../models/product.dart';
import 'add_expense_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({Key? key}) : super(key: key);

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _expensesWithProductNames = [];

  @override
  void initState() {
    super.initState();
    _loadExpensesWithProductNames();
  }

  Future<void> _loadExpensesWithProductNames() async {
    final expenses = await _databaseService.getExpenses();
    final products = await _databaseService.getProducts();

    final mappedExpenses = expenses.map((expense) {
      final product = products.firstWhere(
        (product) => product.id == expense.productId,
        orElse: () => Product(
          id: -1,
          name: 'Неизвестный товар',
          price: 0.0,
          quantity: 0,
          containerId: 0,
        ),
      );

      return {
        'expense': expense,
        'productName': product.name,
      };
    }).toList();

    setState(() {
      _expensesWithProductNames = mappedExpenses;
    });
  }

  Future<void> _navigateToAddExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );
    if (result == true) {
      _loadExpensesWithProductNames();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История расходов')),
      body: Column(
        children: [
          Expanded(
            child: _expensesWithProductNames.isEmpty
                ? const Center(
                    child: Text(
                      'История расходов пуста',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _expensesWithProductNames.length,
                    itemBuilder: (context, index) {
                      final expense = _expensesWithProductNames[index]['expense'] as Expense;
                      final productName = _expensesWithProductNames[index]['productName'] as String;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              expense.quantity.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(productName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Количество: ${expense.quantity}'),
                              Text('Дата: ${expense.date}'),
                              if (expense.dynamicFields != null)
                                ...expense.dynamicFields!.entries.map((entry) {
                                  return Text('${entry.key}: ${entry.value}');
                                }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _navigateToAddExpense,
              icon: const Icon(Icons.add),
              label: const Text('Добавить расход'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}