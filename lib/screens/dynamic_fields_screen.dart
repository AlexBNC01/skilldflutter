import 'package:flutter/material.dart';
import '../services/database_service.dart';

class DynamicFieldsScreen extends StatefulWidget {
  const DynamicFieldsScreen({Key? key}) : super(key: key);

  @override
  State<DynamicFieldsScreen> createState() => _DynamicFieldsScreenState();
}

class _DynamicFieldsScreenState extends State<DynamicFieldsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _fields = [];
  final TextEditingController _fieldNameController = TextEditingController();
  final TextEditingController _fieldLabelController = TextEditingController();
  String _selectedEntity = 'products'; // Для выбора сущности

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final fields = await _db.getDynamicFields(_selectedEntity);
    setState(() {
      _fields = fields;
    });
  }

  Future<void> _addField() async {
    final fieldName = _fieldNameController.text.trim();
    final fieldLabel = _fieldLabelController.text.trim();

    if (fieldName.isEmpty || fieldLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    await _db.insertDynamicField(
      _selectedEntity, // Сущность, куда добавляется поле
      fieldName,      // Имя поля
      fieldLabel,     // Метка поля
      'text',         // Тип поля (например, текстовое поле)
      
    );

    _fieldNameController.clear();
    _fieldLabelController.clear();
    _loadFields();
  }

  Future<void> _deleteField(int id) async {
    await _db.deleteDynamicField(id);
    _loadFields();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление динамическими полями')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedEntity,
              items: const [
                DropdownMenuItem(value: 'products', child: Text('Продукты')),
                DropdownMenuItem(value: 'expenses', child: Text('Расходы')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedEntity = value;
                  });
                  _loadFields();
                }
              },
              decoration: const InputDecoration(labelText: 'Сущность'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fieldNameController,
              decoration: const InputDecoration(labelText: 'Имя поля'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fieldLabelController,
              decoration: const InputDecoration(labelText: 'Метка поля'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addField,
              child: const Text('Добавить поле'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _fields.length,
                itemBuilder: (context, index) {
                  final field = _fields[index];
                  return Card(
                    child: ListTile(
                      title: Text(field['field_label']),
                      subtitle: Text('Имя: ${field['field_name']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteField(field['id']),
                      ),
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