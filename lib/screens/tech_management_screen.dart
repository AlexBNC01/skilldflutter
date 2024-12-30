import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/category.dart';

class TechManagementScreen extends StatefulWidget {
  const TechManagementScreen({Key? key}) : super(key: key);

  @override
  State<TechManagementScreen> createState() => _TechManagementScreenState();
}

class _TechManagementScreenState extends State<TechManagementScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _controller = TextEditingController();
  List<Category> _techs = [];

  @override
  void initState() {
    super.initState();
    _loadTechs();
  }

  Future<void> _loadTechs() async {
    try {
      final tchs = await _db.getTechs();
      setState(() {
        _techs = tchs;
      });
    } catch (e) {
      print('Error loading techs: $e');
    }
  }

  Future<void> _addTech() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final te = Category(name: name);
    try {
      await _db.insertTech(te);
      _controller.clear();
      _loadTechs();
    } catch (e) {
      print('Error adding tech: $e');
    }
  }

  Future<void> _deleteTechById(int id) async {
    try {
      await _db.deleteTech(id);
      _loadTechs();
    } catch (e) {
      print('Error deleting tech: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление техникой'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Название техники',
              ),
            ),
            ElevatedButton(
              onPressed: _addTech,
              child: const Text('Добавить технику'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _techs.length,
                itemBuilder: (context, index) {
                  final te = _techs[index];
                  return ListTile(
                    title: Text(te.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTechById(te.id!),
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