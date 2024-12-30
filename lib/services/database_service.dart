// lib/services/database_service.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/container_model.dart';
import '../models/product.dart';
import '../models/expense.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<void> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'warehouse.db');

    _database = await openDatabase(
      path,
      version: 19, // Увеличиваем версию для миграции
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Включение внешних ключей
    await _database!.execute('PRAGMA foreign_keys = ON;');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    await initDB();
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE techs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE containers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        FOREIGN KEY(parent_id) REFERENCES categories(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        container_id INTEGER NOT NULL,
        image_paths TEXT,
        category_id INTEGER,
        subcategory_id1 INTEGER,
        subcategory_id2 INTEGER,
        type_id INTEGER,
        tech_id INTEGER,
        display_name TEXT,
        number TEXT,
        barcode TEXT UNIQUE, -- Поле теперь nullable и уникальное
        volume REAL,
        created_at TEXT,
        updated_at TEXT,
        dynamic_fields TEXT,
        FOREIGN KEY(container_id) REFERENCES containers(id),
        FOREIGN KEY(category_id) REFERENCES categories(id),
        FOREIGN KEY(type_id) REFERENCES types(id),
        FOREIGN KEY(tech_id) REFERENCES techs(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        date TEXT NOT NULL,
        dynamic_fields TEXT,
        category_id INTEGER,
        type_id INTEGER,
        tech_id INTEGER,
        container_id INTEGER,
        barcode TEXT, -- Добавлено поле barcode
        FOREIGN KEY(product_id) REFERENCES products(id),
        FOREIGN KEY(category_id) REFERENCES categories(id),
        FOREIGN KEY(type_id) REFERENCES types(id),
        FOREIGN KEY(tech_id) REFERENCES techs(id),
        FOREIGN KEY(container_id) REFERENCES containers(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE dynamic_fields (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity TEXT NOT NULL,
        field_name TEXT NOT NULL,
        field_label TEXT NOT NULL,
        field_type TEXT NOT NULL,
        module TEXT,
        options TEXT
      );
    ''');

    // Добавление тестовых данных (опционально)
    await db.insert('types', {'name': 'Тип тестовый'});
    await db.insert('techs', {'name': 'Техника тестовая'});
    await db.insert('containers', {'name': 'Контейнер тестовый'});
    await db.insert('categories', {'name': 'Категория тестовая', 'parent_id': null});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Migrating from version $oldVersion to $newVersion');

    if (oldVersion < 12) {
      await db.execute('ALTER TABLE dynamic_fields ADD COLUMN module TEXT;');
      await db.execute('ALTER TABLE dynamic_fields ADD COLUMN options TEXT;');
      print('Added columns module and options to dynamic_fields');
    }

    if (oldVersion < 13) {
      await db.execute('ALTER TABLE products ADD COLUMN display_name TEXT;');
      // Добавьте другие столбцы, если они были добавлены в версии 13
      print('Added column display_name to products');
    }

    if (oldVersion < 15) {
      // Убедитесь, что barcode уникален
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);');
      print('Created unique index idx_products_barcode on products(barcode)');
    }

    if (oldVersion < 16) { // Новая миграция для таблицы expenses до версии 16
      await db.execute('''
        ALTER TABLE expenses ADD COLUMN category_id INTEGER;
      ''');
      print('Added column category_id to expenses');

      await db.execute('''
        ALTER TABLE expenses ADD COLUMN type_id INTEGER;
      ''');
      print('Added column type_id to expenses');

      await db.execute('''
        ALTER TABLE expenses ADD COLUMN tech_id INTEGER;
      ''');
      print('Added column tech_id to expenses');

      await db.execute('''
        ALTER TABLE expenses ADD COLUMN container_id INTEGER;
      ''');
      print('Added column container_id to expenses');
    }

    if (oldVersion < 18) { // Миграция для версии 18
      await db.execute('''
        ALTER TABLE expenses ADD COLUMN barcode TEXT;
      ''');
      print('Added column barcode to expenses');
    }

    // Добавьте другие миграции, если необходимо

    print('Migration completed');
  }

  // Методы для работы с таблицами

  // Types
  Future<List<Category>> getTypes() async {
    final db = await database;
    try {
      final result = await db.query('types');
      print('Types fetched: $result');
      return result.map((map) => Category.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching types: $e');
      return [];
    }
  }

  Future<int> insertType(Category type) async {
    final db = await database;
    try {
      final id = await db.insert('types', type.toMap());
      print('Type inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting type: $e');
      rethrow;
    }
  }

  Future<void> deleteType(int id) async {
    final db = await database;
    try {
      await db.delete('types', where: 'id = ?', whereArgs: [id]);
      print('Type deleted with id: $id');
    } catch (e) {
      print('Error deleting type: $e');
    }
  }

  // Techs
  Future<List<Category>> getTechs() async {
    final db = await database;
    try {
      final result = await db.query('techs');
      print('Techs fetched: $result');
      return result.map((map) => Category.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching techs: $e');
      return [];
    }
  }

  Future<int> insertTech(Category tech) async {
    final db = await database;
    try {
      final id = await db.insert('techs', tech.toMap());
      print('Tech inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting tech: $e');
      rethrow;
    }
  }

  Future<void> deleteTech(int id) async {
    final db = await database;
    try {
      await db.delete('techs', where: 'id = ?', whereArgs: [id]);
      print('Tech deleted with id: $id');
    } catch (e) {
      print('Error deleting tech: $e');
    }
  }

  // Containers
  Future<List<WarehouseContainer>> getContainers() async {
    final db = await database;
    try {
      final result = await db.query('containers');
      print('Containers fetched: $result');
      return result.map((map) => WarehouseContainer.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching containers: $e');
      return [];
    }
  }

  Future<int> insertContainer(WarehouseContainer container) async {
    final db = await database;
    try {
      final id = await db.insert('containers', container.toMap());
      print('Container inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting container: $e');
      rethrow;
    }
  }

  Future<void> deleteContainer(int id) async {
    final db = await database;
    try {
      await db.delete('containers', where: 'id = ?', whereArgs: [id]);
      print('Container deleted with id: $id');
    } catch (e) {
      print('Error deleting container: $e');
    }
  }

  // Categories
  Future<List<Category>> getCategories() async {
    final db = await database;
    try {
      final result = await db.query('categories');
      print('Categories fetched: $result');
      return result.map((map) => Category.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    try {
      final id = await db.insert('categories', category.toMap());
      print('Category inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    try {
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
      print('Category deleted with id: $id');
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  // Products
  Future<List<Product>> getProducts({int? containerId}) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> result;

      if (containerId != null) {
        result = await db.query(
          'products',
          where: 'container_id = ?',
          whereArgs: [containerId],
        );
      } else {
        result = await db.query('products');
      }

      print('Products fetched: $result');
      return result.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    final productMap = product.toMap();
    productMap['dynamic_fields'] = _mapToJson(product.dynamicFields ?? {});
    try {
      final id = await db.insert('products', productMap);
      print('Product inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting product: $e');
      rethrow;
    }
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    try {
      final result = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        print('Product fetched: ${result.first}');
        return Product.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error fetching product by id: $e');
      return null;
    }
  }

  // Новый метод для поиска продукта по штрих-коду
  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    try {
      final result = await db.query(
        'products',
        where: 'barcode = ?',
        whereArgs: [barcode],
      );

      if (result.isNotEmpty) {
        print('Product fetched by barcode: ${result.first}');
        return Product.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error fetching product by barcode: $e');
      return null;
    }
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    final productMap = product.toMap();
    productMap['dynamic_fields'] = _mapToJson(product.dynamicFields ?? {});
    try {
      await db.update('products', productMap, where: 'id = ?', whereArgs: [product.id]);
      print('Product updated with id: ${product.id}');
    } catch (e) {
      print('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    try {
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
      print('Product deleted with id: $id');
    } catch (e) {
      print('Error deleting product: $e');
    }
  }

  Future<void> updateProductQuantity(int id, int newQuantity) async {
    final db = await database;
    try {
      await db.update(
        'products',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Product quantity updated for id: $id to $newQuantity');
    } catch (e) {
      print('Error updating product quantity: $e');
    }
  }

  Future<Map<String, dynamic>?> getProductDetails(int productId) async {
    final db = await database;
    try {
      final result = await db.rawQuery('''
        SELECT 
          products.id,
          products.name,
          products.price,
          products.quantity,
          products.image_paths AS imagePaths,
          products.display_name AS displayName,
          products.number,
          products.barcode,
          products.volume,
          products.created_at AS createdAt,
          products.updated_at AS updatedAt,
          categories.name AS categoryName,
          types.name AS typeName,
          techs.name AS techName,
          containers.name AS containerName
        FROM products
        LEFT JOIN categories ON products.category_id = categories.id
        LEFT JOIN types ON products.type_id = types.id
        LEFT JOIN techs ON products.tech_id = techs.id
        LEFT JOIN containers ON products.container_id = containers.id
        WHERE products.id = ?
      ''', [productId]);

      if (result.isNotEmpty) {
        print('Product details fetched: ${result.first}');
        return result.first;
      }
      return null;
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }

  // Expenses
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final expenseMap = expense.toMap();
    expenseMap['dynamic_fields'] = _mapToJson(expense.dynamicFields ?? {});
    try {
      final id = await db.insert('expenses', expenseMap);
      print('Expense inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting expense: $e');
      rethrow;
    }
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    try {
      final result = await db.query('expenses');
      print('Expenses fetched: $result');
      return result.map((map) => Expense.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching expenses: $e');
      return [];
    }
  }

  // Dynamic Fields
  Future<int> insertDynamicField(String entity, String fieldName, String fieldLabel, String fieldType) async {
    final db = await database;
    try {
      final id = await db.insert('dynamic_fields', {
        'entity': entity,
        'field_name': fieldName,
        'field_label': fieldLabel,
        'field_type': fieldType,
      });
      print('Dynamic field inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting dynamic field: $e');
      rethrow;
    }
  }

  Future<void> deleteDynamicField(int id) async {
    final db = await database;
    try {
      await db.delete('dynamic_fields', where: 'id = ?', whereArgs: [id]);
      print('Dynamic field deleted with id: $id');
    } catch (e) {
      print('Error deleting dynamic field: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDynamicFields(String entity) async {
    final db = await database;
    try {
      final result = await db.query('dynamic_fields', where: 'entity = ?', whereArgs: [entity]);
      print('Dynamic fields fetched for entity $entity: $result');
      return result;
    } catch (e) {
      print('Error fetching dynamic fields: $e');
      return [];
    }
  }

  // Метод сериализации динамических полей
  String _mapToJson(Map<String, dynamic> map) {
    return jsonEncode(map);
  }
}