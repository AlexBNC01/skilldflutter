// lib/screens/add_dynamic_field_screen.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/dynamic_field.dart'; // Импорт модели DynamicField

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
            // Выбор сущности (продукты или расходы)
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
            // Ввод имени поля
            TextField(
              controller: _fieldNameController,
              decoration: const InputDecoration(labelText: 'Имя поля'),
            ),
            const SizedBox(height: 10),
            // Ввод метки поля
            TextField(
              controller: _fieldLabelController,
              decoration: const InputDecoration(labelText: 'Метка поля'),
            ),
            const SizedBox(height: 10),
            // Выбор типа поля
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
            // Если выбран тип "Выпадающий список", отображаем поле для ввода опций
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
            // Кнопка для добавления динамического поля
            ElevatedButton(
              onPressed: () async {
                final fieldName = _fieldNameController.text.trim();
                final fieldLabel = _fieldLabelController.text.trim();
                final optionsText = _optionsController.text.trim();
                final options = optionsText.isNotEmpty
                    ? optionsText.split(',').map((e) => e.trim()).toList()
                    : null;

                // Проверка обязательных полей
                if (fieldName.isEmpty || fieldLabel.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заполните все обязательные поля')),
                  );
                  return;
                }

                // Создание объекта DynamicField
                final dynamicField = DynamicField(
                  entity: _selectedEntity,
                  fieldName: fieldName,
                  fieldLabel: fieldLabel,
                  fieldType: _selectedFieldType,
                  options: _selectedFieldType == 'dropdown' ? options : null,
                );

                try {
                  // Вставка динамического поля в базу данных
                  await _db.insertDynamicField(dynamicField);

                  // Отображение уведомления об успешном добавлении
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Динамическое поле добавлено')),
                  );

                  // Закрытие экрана и возврат к предыдущему с обновлением данных
                  Navigator.pop(context, true);
                } catch (e) {
                  // Обработка ошибок при добавлении
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка при добавлении поля: $e')),
                  );
                }
              },
              child: const Text('Добавить поле'),
            ),
          ],
        ),
      ),
    );
  }
}