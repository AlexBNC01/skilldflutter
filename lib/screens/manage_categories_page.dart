// lib/screens/manage_categories_page.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/category.dart';

class ManageCategoriesPage extends StatefulWidget {
  final DatabaseService databaseService;

  const ManageCategoriesPage({required this.databaseService, Key? key}) : super(key: key);

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final TextEditingController _categoryNameController = TextEditingController();
  int? _selectedParentId;

  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await widget.databaseService.getCategories();
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _addCategory() async {
    final name = _categoryNameController.text.trim();
    if (name.isEmpty) return;

    final newCategory = Category(
      id: 0, // id будет автоматически назначен базой данных
      name: name,
      parentId: _selectedParentId,
    );

    await widget.databaseService.insertCategory(newCategory);
    _categoryNameController.clear();
    setState(() {
      _selectedParentId = null;
    });
    _loadCategories();
  }

  Future<void> _deleteCategory(int id) async {
    await widget.databaseService.deleteCategory(id);
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
            // Форма для добавления категории
            TextField(
              controller: _categoryNameController,
              decoration: const InputDecoration(labelText: 'Название категории'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: _selectedParentId,
              hint: const Text('Выберите родительскую категорию (не обязательно)'),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Не выбрано'),
                ),
                ..._categories.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedParentId = value;
                });
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Добавить категорию'),
            ),
            const SizedBox(height: 20),
            // Список категорий
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return ListTile(
                    title: Text(cat.name),
                    subtitle: cat.parentId != null
                        ? Text('Родительская категория ID: ${cat.parentId}')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: cat.id != null
                          ? () => _deleteCategory(cat.id!)
                          : null, // Кнопка неактивна, если id == null
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