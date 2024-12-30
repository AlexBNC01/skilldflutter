import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/category.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final DatabaseService _db = DatabaseService();
  List<Category> _categories = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _db.getCategories();
    setState(() {
      _categories = cats;
    });
  }

  Future<void> _addCategory() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final cat = Category(name: name);
    await _db.insertCategory(cat);
    _controller.clear();
    _loadCategories();
  }

  Future<void> _deleteCategory(Category category) async {
    await _db.deleteCategory(category.id!);
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление категориями'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Название категории',
              ),
            ),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Добавить категорию'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return ListTile(
                    title: Text(cat.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCategory(cat),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}