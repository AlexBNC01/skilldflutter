// lib/services/database_service.dart

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/container_model.dart';
import '../models/product.dart';
import '../models/expense.dart';
import '../models/dynamic_field.dart';
import '../models/inventory_log.dart'; // Убедитесь, что у вас есть эта модель

class DatabaseService {
  // Singleton Pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  // Инициализация базы данных
  Future<void> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'warehouse.db');

    _database = await openDatabase(
      path,
      version: 31, // Обновите версию до 31
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Включение внешних ключей
    await _database!.execute('PRAGMA foreign_keys = ON;');
  }

  // Получение экземпляра базы данных
  Future<Database> get database async {
    if (_database != null) return _database!;
    await initDB();
    return _database!;
  }

  // Создание таблиц при первом запуске
  Future<void> _onCreate(Database db, int version) async {
    // Создание таблиц
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
        FOREIGN KEY(parent_id) REFERENCES categories(id) ON DELETE CASCADE
      );
    ''');

    // Создание таблицы продуктов без UNIQUE для barcode
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
        barcode TEXT, -- УБРАЛИ UNIQUE!
        volume REAL,
        created_at TEXT,
        updated_at TEXT,
        dynamic_fields TEXT,
        FOREIGN KEY(container_id) REFERENCES containers(id) ON DELETE CASCADE,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY(type_id) REFERENCES types(id) ON DELETE SET NULL,
        FOREIGN KEY(tech_id) REFERENCES techs(id) ON DELETE SET NULL
      );
    ''');

    // Создание таблицы расходов (expenses) с ON DELETE CASCADE для product_id
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
        barcode TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
        FOREIGN KEY(type_id) REFERENCES types(id) ON DELETE SET NULL,
        FOREIGN KEY(tech_id) REFERENCES techs(id) ON DELETE SET NULL,
        FOREIGN KEY(container_id) REFERENCES containers(id) ON DELETE SET NULL
      );
    ''');

    // Создание таблицы динамических полей
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

    // Создание таблицы журналов инвентаризации (inventory_logs) с ON DELETE CASCADE для product_id
    await db.execute('''
      CREATE TABLE inventory_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        change_type TEXT NOT NULL, -- 'increase' или 'decrease'
        quantity INTEGER NOT NULL,
        date TEXT NOT NULL,
        reason TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      );
    ''');

    // Добавление тестовых данных (опционально)
    await db.insert('types', {'name': 'Тип тестовый'});
    await db.insert('techs', {'name': 'Техника тестовая'});
    await db.insert('containers', {'name': 'Контейнер тестовый'});
    await db.insert('categories', {'name': 'Категория тестовая', 'parent_id': null});
  }

  // Миграции базы данных при обновлении версии
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
      // Удаляем UNIQUE индекс на barcode, если он существует
      print('Removing UNIQUE index idx_products_barcode on products(barcode)');
      await db.execute('DROP INDEX IF EXISTS idx_products_barcode');
    }

    if (oldVersion < 16) {
      // Добавляем новые столбцы в таблицу expenses
      await db.execute('ALTER TABLE expenses ADD COLUMN category_id INTEGER;');
      print('Added column category_id to expenses');

      await db.execute('ALTER TABLE expenses ADD COLUMN type_id INTEGER;');
      print('Added column type_id to expenses');

      await db.execute('ALTER TABLE expenses ADD COLUMN tech_id INTEGER;');
      print('Added column tech_id to expenses');

      await db.execute('ALTER TABLE expenses ADD COLUMN container_id INTEGER;');
      print('Added column container_id to expenses');
    }

    if (oldVersion < 18) {
      await db.execute('ALTER TABLE expenses ADD COLUMN barcode TEXT;');
      print('Added column barcode to expenses');
    }

    if (oldVersion < 21) {
      // Пересоздаём таблицу products без UNIQUE
      print('Dropping and recreating products table without UNIQUE constraint on barcode');

      // Создание временной таблицы без UNIQUE ограничения
      await db.execute('''
        CREATE TABLE products_temp (
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
          barcode TEXT, -- без UNIQUE
          volume REAL,
          created_at TEXT,
          updated_at TEXT,
          dynamic_fields TEXT,
          FOREIGN KEY(container_id) REFERENCES containers(id) ON DELETE CASCADE,
          FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
          FOREIGN KEY(type_id) REFERENCES types(id) ON DELETE SET NULL,
          FOREIGN KEY(tech_id) REFERENCES techs(id) ON DELETE SET NULL
        );
      ''');

      // Копирование данных из старой таблицы в временную
      await db.execute('''
        INSERT INTO products_temp (
          id, name, price, quantity, container_id, image_paths, category_id, subcategory_id1, subcategory_id2, 
          type_id, tech_id, display_name, number, barcode, volume, created_at, updated_at, dynamic_fields
        )
        SELECT 
          id, name, price, quantity, container_id, image_paths, category_id, subcategory_id1, subcategory_id2, 
          type_id, tech_id, display_name, number, barcode, volume, created_at, updated_at, dynamic_fields
        FROM products;
      ''');

      // Удаление старой таблицы
      await db.execute('DROP TABLE products');

      // Переименование временной таблицы в основную
      await db.execute('ALTER TABLE products_temp RENAME TO products');

      print('Recreated products table without UNIQUE barcode constraint without data loss');
    }

    if (oldVersion < 26) {
      // Проверяем, существует ли таблица inventory_logs
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='inventory_logs';");
      if (tables.isEmpty) {
        // Создаём таблицу inventory_logs
        await db.execute('''
          CREATE TABLE inventory_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            change_type TEXT NOT NULL, -- 'increase' или 'decrease'
            quantity INTEGER NOT NULL,
            date TEXT NOT NULL,
            reason TEXT,
            FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
          );
        ''');
        print('Created inventory_logs table');
      } else {
        print('inventory_logs table already exists');
      }
    }

    if (oldVersion < 27) {
      // Добавьте дополнительные миграции здесь, если есть
      print('No additional migrations for version <27');
    }

    // Добавьте миграции для версий 28-31, если они существуют
    if (oldVersion < 31) {
      // Пример: Добавление новых столбцов или таблиц
      // await db.execute('ALTER TABLE ...');
      print('No additional migrations for versions 28-31');
    }

    print('Migration completed');
  }

  // ==========================
  // Методы для типов
  // ==========================
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
      rethrow;
    }
  }

  // ==========================
  // Методы для техников
  // ==========================
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
      rethrow;
    }
  }

  // ==========================
  // Методы для контейнеров
  // ==========================
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
      rethrow;
    }
  }

  // ==========================
  // Методы для категорий
  // ==========================
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
      rethrow;
    }
  }

  // ==========================
  // Методы для продуктов
  // ==========================
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? category,
    String? supplier, // Если хранится в dynamic_fields
    DateTime? startDate,
    DateTime? endDate,
    int? containerId, // Добавленный параметр
    Map<String, dynamic>? dynamicFilters,
  }) async {
    final db = await database;
    try {
      List<String> whereClauses = [];
      List<dynamic> whereArgs = [];

      // Поиск по названию товара
      if (searchQuery != null && searchQuery.isNotEmpty) {
        whereClauses.add('products.name LIKE ?');
        whereArgs.add('%$searchQuery%');
      }

      // Фильтрация по категории
      if (category != null && category.isNotEmpty) {
        whereClauses.add('categories.name = ?');
        whereArgs.add(category);
      }

      // Фильтрация по поставщику (из dynamic_fields)
      if (supplier != null && supplier.isNotEmpty) {
        whereClauses.add('products.dynamic_fields LIKE ?');
        whereArgs.add('%"supplier":"$supplier"%');
      }

      // Фильтрация по container_id
      if (containerId != null) {
        whereClauses.add('products.container_id = ?');
        whereArgs.add(containerId);
      }

      // Фильтрация по дате (например, created_at)
      if (startDate != null && endDate != null) {
        whereClauses.add('products.created_at BETWEEN ? AND ?');
        whereArgs.add(startDate.toIso8601String());
        whereArgs.add(endDate.toIso8601String());
      }

      // Фильтрация по динамическим полям
      if (dynamicFilters != null && dynamicFilters.isNotEmpty) {
        dynamicFilters.forEach((key, value) {
          if (value != null) {
            whereClauses.add('products.dynamic_fields LIKE ?');
            whereArgs.add('%"$key":"$value"%');
          }
        });
      }

      // Формирование WHERE строки
      String whereString = whereClauses.isNotEmpty
          ? whereClauses.join(' AND ')
          : '1=1'; // Используем '1=1' для валидного SQL-запроса

      print('getProducts: Query executed with whereString: $whereString and whereArgs: $whereArgs'); // Логирование

      // Выполнение запроса с соединениями
      final result = await db.rawQuery('''
        SELECT 
          products.*, 
          categories.name AS categoryName,
          types.name AS typeName,
          techs.name AS techName,
          containers.name AS containerName
        FROM products
        LEFT JOIN categories ON products.category_id = categories.id
        LEFT JOIN types ON products.type_id = types.id
        LEFT JOIN techs ON products.tech_id = techs.id
        LEFT JOIN containers ON products.container_id = containers.id
        WHERE $whereString
        ORDER BY products.created_at DESC
      ''', whereArgs);

      return result.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

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

  Future<Product?> getProductById(int id) async {
    final db = await database;
    try {
      final result = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        print('Product fetched by id: ${result.first}');
        return Product.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error fetching product by id: $e');
      return null;
    }
  }

  Future<Product?> getProductDetails(int productId) async {
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
          containers.name AS containerName,
          products.dynamic_fields AS dynamicFields
        FROM products
        LEFT JOIN categories ON products.category_id = categories.id
        LEFT JOIN types ON products.type_id = types.id
        LEFT JOIN techs ON products.tech_id = techs.id
        LEFT JOIN containers ON products.container_id = containers.id
        WHERE products.id = ?
      ''', [productId]);

      if (result.isNotEmpty) {
        print('Product details fetched: ${result.first}');
        return Product.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error fetching product details: $e');
      return null;
    }
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    final productMap = product.toMap();
    try {
      print('Attempting to insert product: $productMap');
      final id = await db.insert('products', productMap);
      print('Product inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    // Исключаем 'id' из обновляемых данных
    final Map<String, dynamic> productMap = Map.from(product.toMap());
    productMap.remove('id');

    try {
      await db.update('products', productMap, where: 'id = ?', whereArgs: [product.id]);
      print('Product updated with id: ${product.id}');
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    try {
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
      print('Product deleted with id: $id');
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // ==========================
  // Методы для динамических полей
  // ==========================
  Future<List<DynamicField>> getDynamicFields(String entity) async {
    final db = await database;
    try {
      final result = await db.query(
        'dynamic_fields',
        where: 'entity = ?',
        whereArgs: [entity],
      );
      print('Dynamic fields fetched for entity $entity: $result');
      return result.map((map) => DynamicField.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching dynamic fields: $e');
      return [];
    }
  }

  Future<int> insertDynamicField(DynamicField dynamicField) async {
    final db = await database;
    try {
      final id = await db.insert('dynamic_fields', dynamicField.toMap());
      print('Dynamic field inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting dynamic field: $e');
      rethrow;
    }
  }

  Future<void> updateDynamicField(DynamicField dynamicField) async {
    final db = await database;
    try {
      await db.update(
        'dynamic_fields',
        dynamicField.toMap(),
        where: 'id = ?',
        whereArgs: [dynamicField.id],
      );
      print('Dynamic field updated with id: ${dynamicField.id}');
    } catch (e) {
      print('Error updating dynamic field: $e');
      rethrow;
    }
  }

  Future<void> deleteDynamicField(int id) async {
    final db = await database;
    try {
      await db.delete(
        'dynamic_fields',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Dynamic field deleted with id: $id');
    } catch (e) {
      print('Error deleting dynamic field: $e');
      rethrow;
    }
  }

  // ==========================
  // Методы для расходов
  // ==========================
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

  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    try {
      final result = await db.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        print('Expense fetched: ${result.first}');
        return Expense.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error fetching expense by id: $e');
      return null;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    final expenseMap = expense.toMap();
    expenseMap['dynamic_fields'] = _mapToJson(expense.dynamicFields ?? {});
    try {
      await db.update('expenses', expenseMap, where: 'id = ?', whereArgs: [expense.id]);
      print('Expense updated with id: ${expense.id}');
    } catch (e) {
      print('Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    try {
      await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
      print('Expense deleted with id: $id');
    } catch (e) {
      print('Error deleting expense: $e');
      rethrow;
    }
  }

  // ==========================
  // Методы для Inventory Logs
  // ==========================
  Future<int> insertInventoryLog(InventoryLog log) async {
    final db = await database;
    try {
      final id = await db.insert('inventory_logs', log.toMap());
      print('Inventory log inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting inventory log: $e');
      rethrow;
    }
  }

  Future<List<InventoryLog>> getInventoryLogs({int? productId}) async {
    final db = await database;
    try {
      List<Map<String, dynamic>> result;

      if (productId != null) {
        result = await db.query(
          'inventory_logs',
          where: 'product_id = ?',
          whereArgs: [productId],
        );
      } else {
        result = await db.query('inventory_logs');
      }

      print('Inventory logs fetched: $result');
      return result.map((map) => InventoryLog.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching inventory logs: $e');
      return [];
    }
  }

  // ==========================
  // Метод сериализации динамических полей
  // ==========================
  String _mapToJson(Map<String, dynamic> map) {
    return jsonEncode(map);
  }

  // ==========================
  // Метод для получения списка уникальных поставщиков из динамических полей
  // ==========================
  Future<List<String>> getSuppliers() async {
    final db = await database;
    try {
      final result = await db.rawQuery(
          'SELECT dynamic_fields FROM products WHERE dynamic_fields LIKE ?', ['%"supplier":"%']);
      final suppliers = <String>{};

      for (var row in result) {
        final dynamicFields = row['dynamic_fields'] as String?;
        if (dynamicFields != null) {
          final Map<String, dynamic> fieldsMap = jsonDecode(dynamicFields);
          if (fieldsMap.containsKey('supplier')) {
            final supplier = fieldsMap['supplier'];
            if (supplier is String && supplier.isNotEmpty) {
              suppliers.add(supplier);
            }
          }
        }
      }

      return suppliers.toList();
    } catch (e) {
      print('Error fetching suppliers: $e');
      return [];
    }
  }

  // ==========================
  // Добавление метода updateProductQuantity
  // ==========================
  /// Обновляет количество продукта по его [productId].
  /// [newQuantity] — новое количество для продукта.
  Future<void> updateProductQuantity(int productId, int newQuantity) async {
    final db = await database;
    try {
      final count = await db.update(
        'products',
        {
          'quantity': newQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );
      if (count == 0) {
        throw Exception('Продукт с id $productId не найден.');
      }
      print('Количество продукта с id $productId обновлено до $newQuantity.');
    } catch (e) {
      print('Ошибка при обновлении количества продукта: $e');
      rethrow;
    }
  }

  // ==========================
  // Метод для проверки существования контейнера
  // ==========================
  Future<bool> containerExists(int containerId) async {
    final db = await database;
    try {
      final result = await db.query(
        'containers',
        where: 'id = ?',
        whereArgs: [containerId],
      );
      bool exists = result.isNotEmpty;
      print('Container with id $containerId exists: $exists');
      return exists;
    } catch (e) {
      print('Error checking if container exists: $e');
      return false;
    }
  }
}