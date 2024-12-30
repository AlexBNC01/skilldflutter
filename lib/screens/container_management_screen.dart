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
  final TextEditingController _controller = TextEditingController();
  List<WarehouseContainer> _containers = [];

  @override
  void initState() {
    super.initState();
    _loadContainers();
  }

  Future<void> _loadContainers() async {
    final conts = await _db.getContainers();
    setState(() {
      _containers = conts;
    });
  }

  Future<void> _addContainer() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await _db.insertContainer(WarehouseContainer(name: name));
    _controller.clear();
    _loadContainers();
  }

  Future<void> _deleteContainerById(int id) async {
    await _db.deleteContainer(id);
    _loadContainers();
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
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Название контейнера',
              ),
            ),
            ElevatedButton(
              onPressed: _addContainer,
              child: const Text('Добавить контейнер'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _containers.length,
                itemBuilder: (context, index) {
                  final c = _containers[index];
                  return ListTile(
                    title: Text(c.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteContainerById(c.id!),
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