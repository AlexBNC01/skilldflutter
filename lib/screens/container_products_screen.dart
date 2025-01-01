// lib/screens/container_products_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/container_model.dart';
import '../models/product.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'product_details_screen.dart';

class ContainerProductsScreen extends StatefulWidget {
  final WarehouseContainer container; // Параметр контейнера

  const ContainerProductsScreen({Key? key, required this.container})
      : super(key: key);

  @override
  State<ContainerProductsScreen> createState() =>
      _ContainerProductsScreenState();
}

class _ContainerProductsScreenState extends State<ContainerProductsScreen> {
  final DatabaseService _db = DatabaseService();

  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Загрузка товаров для данного контейнера
  Future<void> _loadProducts() async {
    try {
      final products = await _db.getProducts(
        containerId: widget.container.id, // Передача containerId отдельно
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
      print('ContainerProductsScreen: Loaded ${products.length} products'); // Логирование
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке продуктов: $e')),
      );
    }
  }

  // Удаление товара
  Future<void> _deleteProduct(int productId) async {
    try {
      await _db.deleteProduct(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Продукт удален')),
      );
      _loadProducts();
    } catch (e) {
      print('Error deleting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении продукта: $e')),
      );
    }
  }

  // Обновление списка после добавления/редактирования
  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
    if (result == true) {
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Продукты: ${widget.container.name}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('Нет продуктов в этом контейнере'))
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: product.imagePathsList.isNotEmpty
                              ? Image.file(
                                  File(product.imagePathsList.first),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image, size: 50),
                          title: Text(product.name),
                          subtitle: Text('Количество: ${product.quantity}'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailsScreen(productId: product.id!),
                              ),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditProductScreen(productId: product.id!),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadProducts();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteProduct(product.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
}