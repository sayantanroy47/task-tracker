import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

/// Database service singleton for managing SQLite database operations
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'task_tracker.db';
  static const int _databaseVersion = 1;

  /// Get database instance, initializing if necessary
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database with tables and default data
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database settings
  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create database tables on first installation
  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertDefaultData(db);
  }

  /// Handle database migrations for future versions
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic will be added here for future versions
    // For now, we only have version 1
  }

  /// Create all database tables
  Future<void> _createTables(Database db) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL,
        icon TEXT NOT NULL,
        is_system INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Create tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category_id INTEGER NOT NULL,
        due_date TEXT,
        due_time TEXT,
        priority INTEGER DEFAULT 1,
        completed INTEGER DEFAULT 0,
        source TEXT DEFAULT 'manual',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Create notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        scheduled_time TEXT NOT NULL,
        type TEXT NOT NULL,
        sent INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_tasks_category_id ON tasks (category_id)');
    await db.execute('CREATE INDEX idx_tasks_due_date ON tasks (due_date)');
    await db.execute('CREATE INDEX idx_tasks_completed ON tasks (completed)');
    await db.execute('CREATE INDEX idx_tasks_created_at ON tasks (created_at)');
    await db.execute('CREATE INDEX idx_notifications_task_id ON notifications (task_id)');
    await db.execute('CREATE INDEX idx_notifications_scheduled_time ON notifications (scheduled_time)');
  }

  /// Insert default categories and sample data
  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Insert default categories
    final defaultCategories = [
      {
        'name': 'Personal',
        'color': Colors.blue.value,
        'icon': 'person',
        'is_system': 1,
        'created_at': now,
      },
      {
        'name': 'Household',
        'color': Colors.green.value,
        'icon': 'home',
        'is_system': 1,
        'created_at': now,
      },
      {
        'name': 'Work',
        'color': Colors.orange.value,
        'icon': 'work',
        'is_system': 1,
        'created_at': now,
      },
      {
        'name': 'Family',
        'color': Colors.red.value,
        'icon': 'family_restroom',
        'is_system': 1,
        'created_at': now,
      },
      {
        'name': 'Health',
        'color': Colors.purple.value,
        'icon': 'favorite',
        'is_system': 1,
        'created_at': now,
      },
      {
        'name': 'Finance',
        'color': Colors.amber.value,
        'icon': 'attach_money',
        'is_system': 1,
        'created_at': now,
      },
    ];

    for (final category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Reset database (useful for testing)
  Future<void> reset() async {
    await close();
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);
    await deleteDatabase(path);
  }

  /// Check if database exists
  Future<bool> exists() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, _databaseName);
    return await databaseExists(path);
  }
}