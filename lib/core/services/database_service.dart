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
        id TEXT PRIMARY KEY,
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
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        category_id TEXT NOT NULL,
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
        task_id TEXT NOT NULL,
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
    await db.execute('CREATE INDEX idx_tasks_updated_at ON tasks (updated_at)');
    await db.execute('CREATE INDEX idx_tasks_priority ON tasks (priority)');
    await db.execute('CREATE INDEX idx_tasks_source ON tasks (source)');
    await db.execute('CREATE INDEX idx_notifications_task_id ON notifications (task_id)');
    await db.execute('CREATE INDEX idx_notifications_scheduled_time ON notifications (scheduled_time)');
    
    // Composite indexes for common queries
    await db.execute('CREATE INDEX idx_tasks_completed_due_date ON tasks (completed, due_date)');
    await db.execute('CREATE INDEX idx_tasks_category_completed ON tasks (category_id, completed)');
    await db.execute('CREATE INDEX idx_tasks_priority_due_date ON tasks (priority, due_date)');
    
    // Full-text search virtual table for efficient text search
    await db.execute('''
      CREATE VIRTUAL TABLE tasks_fts USING fts5(
        title, 
        description, 
        content='tasks', 
        content_rowid='id'
      )
    ''');
    
    // Trigger to keep FTS table in sync with tasks table
    await db.execute('''
      CREATE TRIGGER tasks_fts_insert AFTER INSERT ON tasks BEGIN
        INSERT INTO tasks_fts(rowid, title, description) 
        VALUES (new.id, new.title, new.description);
      END
    ''');
    
    await db.execute('''
      CREATE TRIGGER tasks_fts_delete AFTER DELETE ON tasks BEGIN
        INSERT INTO tasks_fts(tasks_fts, rowid, title, description) 
        VALUES('delete', old.id, old.title, old.description);
      END
    ''');
    
    await db.execute('''
      CREATE TRIGGER tasks_fts_update AFTER UPDATE ON tasks BEGIN
        INSERT INTO tasks_fts(tasks_fts, rowid, title, description) 
        VALUES('delete', old.id, old.title, old.description);
        INSERT INTO tasks_fts(rowid, title, description) 
        VALUES (new.id, new.title, new.description);
      END
    ''');
  }

  /// Insert default categories and sample data
  Future<void> _insertDefaultData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Insert default categories
    final defaultCategories = [
      {
        'id': 'personal',
        'name': 'Personal',
        'color': Colors.blue.value,
        'icon': 'person',
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'household',
        'name': 'Household',
        'color': Colors.green.value,
        'icon': 'home',
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'work',
        'name': 'Work',
        'color': Colors.orange.value,
        'icon': 'work',
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'family',
        'name': 'Family',
        'color': Colors.red.value,
        'icon': 'family_restroom',
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'health',
        'name': 'Health',
        'color': Colors.purple.value,
        'icon': 'favorite',
        'is_system': 1,
        'created_at': now,
      },
      {
        'id': 'finance',
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

  /// Get database performance statistics
  Future<Map<String, dynamic>> getPerformanceStats() async {
    final db = await database;
    
    // Get table row counts
    final taskCount = await db.rawQuery('SELECT COUNT(*) as count FROM tasks');
    final categoryCount = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
    final notificationCount = await db.rawQuery('SELECT COUNT(*) as count FROM notifications');
    
    // Get database size
    final dbStats = await db.rawQuery('PRAGMA page_count');
    final pageSize = await db.rawQuery('PRAGMA page_size');
    final pageCount = dbStats.first['page_count'] as int;
    final pageSizeBytes = pageSize.first['page_size'] as int;
    final dbSizeBytes = pageCount * pageSizeBytes;
    
    // Get index usage stats
    final indexStats = await db.rawQuery('''
      SELECT name, tbl_name FROM sqlite_master 
      WHERE type = 'index' AND name NOT LIKE 'sqlite_%'
    ''');
    
    return {
      'taskCount': taskCount.first['count'],
      'categoryCount': categoryCount.first['count'],
      'notificationCount': notificationCount.first['count'],
      'databaseSizeBytes': dbSizeBytes,
      'databaseSizeMB': (dbSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'indexCount': indexStats.length,
      'pageCount': pageCount,
      'pageSize': pageSizeBytes,
    };
  }

  /// Analyze query performance
  Future<String> explainQuery(String query, [List<dynamic>? arguments]) async {
    final db = await database;
    final result = await db.rawQuery('EXPLAIN QUERY PLAN $query', arguments);
    return result.map((row) => row.values.join(' | ')).join('\n');
  }

  /// Vacuum database to reclaim space and optimize performance
  Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  /// Rebuild FTS index
  Future<void> rebuildFTSIndex() async {
    final db = await database;
    await db.execute('INSERT INTO tasks_fts(tasks_fts) VALUES("rebuild")');
  }

  /// Get FTS search performance stats
  Future<Map<String, dynamic>> getFTSStats() async {
    final db = await database;
    
    try {
      final ftsRows = await db.rawQuery('SELECT COUNT(*) as count FROM tasks_fts');
      final ftsIntegrity = await db.rawQuery('INSERT INTO tasks_fts(tasks_fts) VALUES("integrity-check")');
      
      return {
        'ftsRowCount': ftsRows.first['count'],
        'ftsIntegrityOk': true,
      };
    } catch (e) {
      return {
        'ftsRowCount': 0,
        'ftsIntegrityOk': false,
        'error': e.toString(),
      };
    }
  }
}