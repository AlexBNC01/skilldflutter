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

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _db.getProducts(containerId: widget.container.id);
    setState(() {
      _products = products;
    });
  }

  void _onAddProduct() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(containerId: widget.container.id!),
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
      body: _products.isEmpty
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
                      'Цена: ${product.price.toStringAsFixed(2)}\nКоличество: ${product.quantity}',
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
                        await _db.deleteProduct(product.id!);
                        _loadProducts();
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