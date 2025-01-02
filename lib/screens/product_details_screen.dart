// lib/screens/product_details_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/product.dart';
import '../models/dynamic_field.dart';
import 'dart:convert';

class ProductDetailsScreen extends StatefulWidget {
  final int productId;

  const ProductDetailsScreen({required this.productId, Key? key}) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final DatabaseService _db = DatabaseService();
  Product? _product;
  List<DynamicField> _dynamicFields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      print('Загрузка деталей продукта...');
      final productDetails = await _db.getProductDetails(widget.productId);
      if (productDetails != null) {
        final dynamicFields = await _db.getDynamicFields('products');
        setState(() {
          _product = productDetails;
          _dynamicFields = dynamicFields;
          _isLoading = false;
        });
        print('Детали продукта загружены успешно.');
      } else {
        setState(() {
          _product = null;
          _dynamicFields = [];
          _isLoading = false;
        });
        print('Товар не найден.');
      }
    } catch (e) {
      print('Ошибка при загрузке деталей продукта: $e');
      setState(() {
        _product = null;
        _dynamicFields = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Товар не найден')),
        body: const Center(child: Text('Данный товар не найден')),
      );
    }

    final images = _product!.imagePathsList;
    final createdAt = _product!.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(_product!.createdAt!)
        : 'Неизвестно';
    final dynamicValues = _product!.dynamicFields ?? {};

    return Scaffold(
      appBar: AppBar(title: Text(_product!.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображения продукта
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
                    height: 250,
                    child: PageView.builder(
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        final imagePath = images[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Индикаторы страниц
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade400,
                        ),
                      );
                    }),
                  ),
                ],
              )
            else
              const Text(
                'Нет изображений',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

            const SizedBox(height: 20),

            // Карточка с информацией о продукте
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
                    // Название продукта с Hero
                    Hero(
                      tag: 'productHero_${_product!.id}', // Уникальный тег
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          _product!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Цена
                    if (_product!.price != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.attach_money, color: Colors.green),
                        title: const Text('Цена'),
                        subtitle: Text('${_product!.price} ₽'),
                      ),

                    // Количество
                    if (_product!.quantity != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.inventory, color: Colors.blue),
                        title: const Text('Количество'),
                        subtitle: Text('${_product!.quantity}'),
                      ),

                    // Дата добавления
                    if (_product!.createdAt != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, color: Colors.orange),
                        title: const Text('Дата добавления'),
                        subtitle: Text(createdAt),
                      ),

                    // Категория
                    if (_product!.categoryName != null && _product!.categoryName!.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.category, color: Colors.purple),
                        title: const Text('Категория'),
                        subtitle: Text(_product!.categoryName!),
                      ),

                    // Тип
                    if (_product!.typeName != null && _product!.typeName!.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.label, color: Colors.teal),
                        title: const Text('Тип'),
                        subtitle: Text(_product!.typeName!),
                      ),

                    // Техника
                    if (_product!.techName != null && _product!.techName!.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.build, color: Colors.red),
                        title: const Text('Техника'),
                        subtitle: Text(_product!.techName!),
                      ),

                    // Штрих-код
                    if (_product!.barcode != null && _product!.barcode!.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.qr_code, color: Colors.grey),
                        title: const Text('Штрих-код'),
                        subtitle: Text(_product!.barcode!),
                      ),

                    // Контейнер
                    if (_product!.containerName != null && _product!.containerName!.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.storage, color: Colors.brown),
                        title: const Text('Контейнер'),
                        subtitle: Text(_product!.containerName!),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Динамические дополнительные поля
            if (dynamicValues.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Дополнительные характеристики:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: _dynamicFields.map((field) {
                          final value = dynamicValues[field.fieldName];
                          if (value == null ||
                              (value is String && value.trim().isEmpty)) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${field.fieldLabel}:',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '$value',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}