import 'dart:io';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import 'product_details_screen.dart';
import 'edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final DatabaseService _db = DatabaseService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final products = await _db.getProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  Widget _buildProductImage(String? imagePaths) {
    if (imagePaths == null || imagePaths.isEmpty) {
      return const Icon(Icons.image, size: 50);
    }

    final paths = imagePaths.split(',');
    final file = File(paths.first.trim());
    return file.existsSync()
        ? Image.file(file, width: 50, height: 50, fit: BoxFit.cover)
        : const Icon(Icons.image_not_supported, size: 50);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return const Center(child: Text('Нет товаров'));
    }

    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: _buildProductImage(product.imagePaths),
            title: Text(product.name, style: const TextStyle(fontSize: 16)),
            subtitle: Text(
              'Цена: ${product.price.toStringAsFixed(2)}\nКоличество: ${product.quantity}',
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(productId: product.id!),
                ),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(productId: product.id!),
                  ),
                ).then((value) => _loadProducts());
              },
            ),
          ),
        );
      },
    );
  }
}