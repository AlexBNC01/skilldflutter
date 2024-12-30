import 'package:flutter/material.dart';
import '../services/database_service.dart';

class AddDynamicFieldScreen extends StatefulWidget {
  const AddDynamicFieldScreen({Key? key}) : super(key: key);

  @override
  State<AddDynamicFieldScreen> createState() => _AddDynamicFieldScreenState();
}

class _AddDynamicFieldScreenState extends State<AddDynamicFieldScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _fieldNameController = TextEditingController();
  final TextEditingController _fieldLabelController = TextEditingController();
  final TextEditingController _optionsController = TextEditingController();
  String _selectedEntity = 'products';
  String _selectedFieldType = 'text';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить динамическое поле')),
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
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedFieldType,
              items: const [
                DropdownMenuItem(value: 'text', child: Text('Текст')),
                DropdownMenuItem(value: 'number', child: Text('Число')),
                DropdownMenuItem(value: 'dropdown', child: Text('Выпадающий список')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFieldType = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Тип поля'),
            ),
            if (_selectedFieldType == 'dropdown') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _optionsController,
                decoration: const InputDecoration(
                  labelText: 'Опции (через запятую)',
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final fieldName = _fieldNameController.text.trim();
                final fieldLabel = _fieldLabelController.text.trim();
                final options = _optionsController.text.trim().split(',');

                if (fieldName.isEmpty || fieldLabel.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заполните все поля')),
                  );
                  return;
                }

                await _db.insertDynamicField(
                  _selectedEntity,
                  fieldName,
                  fieldLabel,
                  _selectedFieldType,
                  
                );

                Navigator.pop(context, true); // Закрыть экран после добавления
              },
              child: const Text('Добавить поле'),
            ),
          ],
        ),
      ),
    );
  }
}