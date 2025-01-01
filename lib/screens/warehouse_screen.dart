// warehouse
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/container_model.dart';
import 'container_products_screen.dart';

class WarehouseScreen extends StatefulWidget {
  const WarehouseScreen({Key? key}) : super(key: key);

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _containerNameController = TextEditingController();
  List<WarehouseContainer> _containers = [];

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
    final name = _containerNameController.text.trim();
    if (name.isNotEmpty) {
      await _db.insertContainer(WarehouseContainer(name: name));
      _containerNameController.clear();
      _loadContainers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Склад'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _containerNameController,
                    decoration:
                        const InputDecoration(labelText: 'Название контейнера'),
                  ),
                ),
                IconButton(
                  onPressed: _addContainer,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: _containers.isEmpty
                ? const Center(child: Text('Нет контейнеров'))
                : ListView.builder(
                    itemCount: _containers.length,
                    itemBuilder: (context, index) {
                      final container = _containers[index];
                      return ListTile(
                        title: Text(container.name),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ContainerProductsScreen(container: container),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _db.deleteContainer(container.id!);
                            _loadContainers();
                          },
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}