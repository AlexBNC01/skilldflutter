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
  Category? _selectedParent;

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

    final cat = Category(name: name, parentId: _selectedParent?.id);
    await _db.insertCategory(cat);
    _controller.clear();
    _selectedParent = null;
    _loadCategories();
  }

  Future<void> _deleteCategory(Category category) async {
    await _db.deleteCategory(category.id!);
    _loadCategories();
  }

  List<Category> _getRootCategories() {
    return _categories.where((c) => c.parentId == null).toList();
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
                labelText: 'Название категории/подкатегории',
              ),
            ),
            const SizedBox(height: 10),
            DropdownButton<Category>(
              value: _selectedParent,
              hint: const Text('Выберите родительскую категорию (опционально)'),
              isExpanded: true,
              items: [null, ..._categories].map((cat) {
                if (cat == null) {
                  return const DropdownMenuItem<Category>(
                    value: null,
                    child: Text('Без родителя'),
                  );
                }
                return DropdownMenuItem<Category>(
                  value: cat,
                  child: Text(cat.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedParent = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Добавить категорию'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: _categories.map((cat) {
                  return ListTile(
                    title: Text(cat.name),
                    subtitle: cat.parentId == null ? null : Text('Подчинена категории ID: ${cat.parentId}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCategory(cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}