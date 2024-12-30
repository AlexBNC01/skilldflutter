// lib/screens/container_management_screen.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/container_model.dart';

class ContainerManagementScreen extends StatefulWidget {
  const ContainerManagementScreen({Key? key}) : super(key: key);

  @override
  State<ContainerManagementScreen> createState() => _ContainerManagementScreenState();
}

class _ContainerManagementScreenState extends State<ContainerManagementScreen> {
  final DatabaseService _db = DatabaseService();
  List<WarehouseContainer> _containers = [];
  final TextEditingController _containerNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  Future<void> _loadContainers() async {
    final containers = await _db.getContainers();
    setState(() {
      _containers = containers;
    });
  }

  Future<void> _addContainer() async {
    final containerName = _containerNameController.text.trim();

    if (containerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, введите название контейнера.')),
      );
      return;
    }

    final newContainer = WarehouseContainer(
      name: containerName,
    );

    try {
      await _db.insertContainer(newContainer);
      _containerNameController.clear();
      await _loadContainers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка добавления контейнера: $e')),
      );
    }
  }

  Future<void> _deleteContainer(int id) async {
    try {
      await _db.deleteContainer(id);
      await _loadContainers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления контейнера: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Управление контейнерами')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _containerNameController,
                decoration: const InputDecoration(labelText: 'Название контейнера'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addContainer,
                child: const Text('Добавить контейнер'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _containers.isEmpty
                    ? const Center(child: Text('Контейнеры отсутствуют.'))
                    : ListView.builder(
                        itemCount: _containers.length,
                        itemBuilder: (context, index) {
                          final container = _containers[index];
                          return Card(
                            child: ListTile(
                              title: Text(container.name),
                              subtitle: Text('ID: ${container.id}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteContainer(container.id!),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ));
  }
}