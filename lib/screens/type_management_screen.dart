import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/category.dart';

class TypeManagementScreen extends StatefulWidget {
  const TypeManagementScreen({Key? key}) : super(key: key);

  @override
  State<TypeManagementScreen> createState() => _TypeManagementScreenState();
}

class _TypeManagementScreenState extends State<TypeManagementScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _controller = TextEditingController();
  List<Category> _types = [];

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    try {
      final typs = await _db.getTypes();
      setState(() {
        _types = typs;
      });
    } catch (e) {
      print('Error loading types: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки типов: $e')),
      );
    }
  }

  Future<void> _addType() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название типа')),
      );
      return;
    }

    final type = Category(name: name);
    try {
      await _db.insertType(type);
      _controller.clear();
      await _loadTypes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тип добавлен')),
      );
      // Возвращаем результат true для обновления данных на предыдущем экране
      Navigator.pop(context, true);
    } catch (e) {
      print('Error adding type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при добавлении типа: $e')),
      );
    }
  }

  Future<void> _deleteTypeById(int id) async {
    try {
      await _db.deleteType(id);
      await _loadTypes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Тип удален')),
      );
    } catch (e) {
      print('Error deleting type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении типа: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление типами'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Название типа',
              ),
            ),
            ElevatedButton(
              onPressed: _addType,
              child: const Text('Добавить тип'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _types.isEmpty
                  ? const Center(child: Text('Нет типов для отображения'))
                  : ListView.builder(
                      itemCount: _types.length,
                      itemBuilder: (context, index) {
                        final type = _types[index];
                        return ListTile(
                          title: Text(type.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTypeById(type.id!),
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