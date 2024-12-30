import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/product.dart';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;

  const ProductDetailsScreen({required this.productId, Key? key}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _productDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    final productDetails = await _db.getProductDetails(widget.productId);
    if (mounted) {
      setState(() {
        _productDetails = productDetails;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_productDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Товар не найден')),
        body: const Center(child: Text('Данный товар не найден')),
      );
    }

    final images = (_productDetails!['imagePaths'] as String?)
        ?.split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList() ?? [];

    final createdAt = _productDetails!['createdAt'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(_productDetails!['createdAt']))
        : 'Неизвестно';

    return Scaffold(
      appBar: AppBar(title: Text(_productDetails!['name'] as String)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Карточка информации
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productDetails!['name'] as String,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Цена: ${_productDetails!['price']} ₽',
                      style: const TextStyle(fontSize: 18, color: Colors.green),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Количество: ${_productDetails!['quantity']}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Дата добавления: $createdAt',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Divider(height: 20),
                    if (_productDetails!['categoryName'] != null)
                      Text('Категория: ${_productDetails!['categoryName']}', style: const TextStyle(fontSize: 16)),
                    if (_productDetails!['typeName'] != null)
                      Text('Тип: ${_productDetails!['typeName']}', style: const TextStyle(fontSize: 16)),
                    if (_productDetails!['techName'] != null)
                      Text('Техника: ${_productDetails!['techName']}', style: const TextStyle(fontSize: 16)),
                    if (_productDetails!['barcode'] != null)
                      Text('Штрих-код: ${_productDetails!['barcode']}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Блок с изображениями
            if (images.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Изображения:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final imagePath = images[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.file(
                              File(imagePath),
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            else
              const Text('Нет изображений', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}