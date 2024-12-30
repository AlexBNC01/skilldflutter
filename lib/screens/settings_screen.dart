// setting_screen
import 'package:flutter/material.dart';
import 'categories_management_screen.dart';
import 'container_management_screen.dart';
import 'type_management_screen.dart';
import 'tech_management_screen.dart';
import 'dynamic_fields_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Управление категориями'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Управление контейнерами'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContainerManagementScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Управление типами'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TypeManagementScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Управление техникой'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TechManagementScreen()),
              );
            },
          ),
          ListTile(
            title: const Text('Управление динамическими полями'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DynamicFieldsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}