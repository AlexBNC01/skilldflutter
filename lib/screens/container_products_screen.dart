// lib/screens/container_products_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/container_model.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';

class ContainerProductsScreen extends StatefulWidget {
  final WarehouseContainer container;

  const ContainerProductsScreen({required this.container, Key? key})
      : super(key: key);

  @override
  State<ContainerProductsScreen> createState() =>
      _ContainerProductsScreenState();
}

class _ContainerProductsScreenState extends State<ContainerProductsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Product> _products = [];
  bool _isLoading = true; // Добавлено для отображения индикатора загрузки

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _db.getProducts(containerId: widget.container.id);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки продуктов: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки продуктов: $e')),
      );
    }
  }

  void _onAddProduct() async {
    // Удалена передача containerId
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );
    _loadProducts();
  }

  Widget _buildProductImages(String? imagePaths) {
    if (imagePaths == null || imagePaths.isEmpty) {
      return const Icon(Icons.image, size: 50);
    }

    final paths = imagePaths.split(',');
    return Row(
      children: paths.take(3).map((path) {
        final file = File(path.trim());
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: file.existsSync()
              ? Image.file(
                  file,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                )
              : const Icon(Icons.image_not_supported, size: 50),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Контейнер: ${widget.container.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Text(
                    'Нет товаров в этом контейнере',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: _buildProductImages(product.imagePaths),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                        subtitle: Text(
                          'Цена: ${product.price.toStringAsFixed(2)} ₽\nКоличество: ${product.quantity}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailsScreen(productId: product.id!),
                            ),
                          );
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            // Подтверждение перед удалением
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Подтверждение'),
                                content: const Text(
                                    'Вы уверены, что хотите удалить этот товар?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Отмена'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Удалить'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _db.deleteProduct(product.id!);
                              _loadProducts();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
}