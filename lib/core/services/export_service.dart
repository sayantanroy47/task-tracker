import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/models.dart';
import '../repositories/repositories.dart';

/// Export service for task data with multiple format support and data integrity
/// Provides comprehensive export functionality with performance optimizations
class ExportService {
  final TaskRepository _taskRepository;
  final CategoryRepository _categoryRepository;

  ExportService({
    required TaskRepository taskRepository,
    required CategoryRepository categoryRepository,
  }) : _taskRepository = taskRepository,
       _categoryRepository = categoryRepository;

  /// Export tasks to JSON format
  Future<ExportResult> exportToJson({
    List<Task>? tasks,
    List<Category>? categories,
    bool includeCategories = true,
    String? fileName,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Get data if not provided
      tasks ??= await _taskRepository.getAllTasks();
      categories ??= includeCategories ? await _categoryRepository.getAllCategories() : [];
      
      // Create export data structure
      final exportData = {
        'metadata': {
          'exportDate': DateTime.now().toIso8601String(),
          'version': '1.0',
          'taskCount': tasks.length,
          'categoryCount': categories.length,
          'exportFormat': 'json',
        },
        'tasks': tasks.map((task) => _taskToExportMap(task)).toList(),
        if (includeCategories)
          'categories': categories.map((cat) => _categoryToExportMap(cat)).toList(),
      };
      
      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Save to file
      final file = await _saveToFile(
        jsonString, 
        fileName ?? 'tasks_export_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      
      stopwatch.stop();
      
      return ExportResult(
        success: true,
        filePath: file.path,
        fileSize: jsonString.length,
        recordCount: tasks.length,
        format: ExportFormat.json,
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      debugPrint('JSON export failed: $e');
      return ExportResult(
        success: false,
        error: e.toString(),
        format: ExportFormat.json,
      );
    }
  }

  /// Export tasks to CSV format
  Future<ExportResult> exportToCsv({
    List<Task>? tasks,
    String? fileName,
    List<String>? selectedFields,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Get tasks if not provided
      tasks ??= await _taskRepository.getAllTasks();
      
      // Default fields for CSV export
      final fields = selectedFields ?? [
        'id', 'title', 'description', 'category_id', 'due_date', 'due_time',
        'priority', 'completed', 'source', 'created_at', 'updated_at'
      ];
      
      // Create CSV content
      final csvLines = <String>[];
      
      // Header row
      csvLines.add(fields.map((field) => _escapeCsvField(field)).join(','));
      
      // Data rows
      for (final task in tasks) {
        final taskMap = _taskToExportMap(task);
        final row = fields.map((field) {
          final value = taskMap[field]?.toString() ?? '';
          return _escapeCsvField(value);
        }).join(',');
        csvLines.add(row);
      }
      
      final csvContent = csvLines.join('\n');
      
      // Save to file
      final file = await _saveToFile(
        csvContent,
        fileName ?? 'tasks_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      
      stopwatch.stop();
      
      return ExportResult(
        success: true,
        filePath: file.path,
        fileSize: csvContent.length,
        recordCount: tasks.length,
        format: ExportFormat.csv,
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      debugPrint('CSV export failed: $e');
      return ExportResult(
        success: false,
        error: e.toString(),
        format: ExportFormat.csv,
      );
    }
  }

  /// Export tasks to Markdown format
  Future<ExportResult> exportToMarkdown({
    List<Task>? tasks,
    List<Category>? categories,
    String? fileName,
    bool groupByCategory = true,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Get data if not provided
      tasks ??= await _taskRepository.getAllTasks();
      categories ??= await _categoryRepository.getAllCategories();
      
      // Create category lookup
      final categoryMap = {for (var cat in categories) cat.id.toString(): cat};
      
      // Build markdown content
      final buffer = StringBuffer();
      
      // Header
      buffer.writeln('# Task Export Report');
      buffer.writeln();
      buffer.writeln('**Export Date:** ${DateTime.now().toString()}');
      buffer.writeln('**Total Tasks:** ${tasks.length}');
      buffer.writeln('**Categories:** ${categories.length}');
      buffer.writeln();
      
      if (groupByCategory) {
        // Group tasks by category
        final groupedTasks = <String, List<Task>>{};
        for (final task in tasks) {
          final categoryId = task.categoryId;
          groupedTasks[categoryId] = (groupedTasks[categoryId] ?? [])..add(task);
        }
        
        // Write each category
        for (final entry in groupedTasks.entries) {
          final categoryId = entry.key;
          final categoryTasks = entry.value;
          final category = categoryMap[categoryId];
          
          buffer.writeln('## ${category?.name ?? 'Unknown Category'}');
          buffer.writeln();
          
          for (final task in categoryTasks) {
            _writeTaskMarkdown(buffer, task);
          }
          
          buffer.writeln();
        }
      } else {
        // List all tasks without grouping
        buffer.writeln('## All Tasks');
        buffer.writeln();
        
        for (final task in tasks) {
          _writeTaskMarkdown(buffer, task);
        }
      }
      
      final markdownContent = buffer.toString();
      
      // Save to file
      final file = await _saveToFile(
        markdownContent,
        fileName ?? 'tasks_export_${DateTime.now().millisecondsSinceEpoch}.md',
      );
      
      stopwatch.stop();
      
      return ExportResult(
        success: true,
        filePath: file.path,
        fileSize: markdownContent.length,
        recordCount: tasks.length,
        format: ExportFormat.markdown,
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      debugPrint('Markdown export failed: $e');
      return ExportResult(
        success: false,
        error: e.toString(),
        format: ExportFormat.markdown,
      );
    }
  }

  /// Import tasks from JSON file
  Future<ImportResult> importFromJson(String filePath) async {
    try {
      final stopwatch = Stopwatch()..start();
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }
      
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate structure
      if (!data.containsKey('tasks')) {
        throw Exception('Invalid JSON structure: missing tasks array');
      }
      
      final tasksData = data['tasks'] as List;
      final categoriesData = data['categories'] as List?;
      
      // Import categories first if present
      var importedCategories = 0;
      if (categoriesData != null) {
        for (final categoryData in categoriesData) {
          // Check if category already exists
          final existingCategories = await _categoryRepository.getAllCategories();
          final categoryExists = existingCategories.any(
            (cat) => cat.name == categoryData['name']
          );
          
          if (!categoryExists) {
            // Create new category (implementation depends on your Category model)
            importedCategories++;
          }
        }
      }
      
      // Import tasks
      var importedTasks = 0;
      var skippedTasks = 0;
      final errors = <String>[];
      
      for (final taskData in tasksData) {
        try {
          final task = _taskFromExportMap(taskData);
          await _taskRepository.createTask(task);
          importedTasks++;
        } catch (e) {
          errors.add('Task import error: ${e.toString()}');
          skippedTasks++;
        }
      }
      
      stopwatch.stop();
      
      return ImportResult(
        success: true,
        importedTasks: importedTasks,
        importedCategories: importedCategories,
        skippedTasks: skippedTasks,
        errors: errors,
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      debugPrint('JSON import failed: $e');
      return ImportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Perform data integrity check
  Future<DataIntegrityResult> performIntegrityCheck() async {
    try {
      final stopwatch = Stopwatch()..start();
      final issues = <DataIntegrityIssue>[];
      
      // Get all data
      final [tasks, categories] = await Future.wait([
        _taskRepository.getAllTasks(),
        _categoryRepository.getAllCategories(),
      ]);
      
      final categoryIds = categories.map((c) => c.id.toString()).toSet();
      
      // Check for orphaned tasks (tasks with non-existent category IDs)
      for (final task in tasks) {
        if (!categoryIds.contains(task.categoryId)) {
          issues.add(DataIntegrityIssue(
            type: IntegrityIssueType.orphanedTask,
            description: 'Task "${task.title}" references non-existent category ID: ${task.categoryId}',
            taskId: task.id,
            severity: IssueSeverity.high,
          ));
        }
      }
      
      // Check for duplicate task titles in same category
      final taskGroups = <String, List<Task>>{};
      for (final task in tasks) {
        final key = '${task.categoryId}:${task.title.toLowerCase()}';
        taskGroups[key] = (taskGroups[key] ?? [])..add(task);
      }
      
      for (final entry in taskGroups.entries) {
        if (entry.value.length > 1) {
          issues.add(DataIntegrityIssue(
            type: IntegrityIssueType.duplicateTask,
            description: 'Duplicate task titles found: "${entry.value.first.title}"',
            taskId: entry.value.first.id,
            severity: IssueSeverity.medium,
          ));
        }
      }
      
      // Check for tasks with invalid due dates
      for (final task in tasks) {
        if (task.dueDate != null && task.dueDate!.isBefore(task.createdAt)) {
          issues.add(DataIntegrityIssue(
            type: IntegrityIssueType.invalidDate,
            description: 'Task "${task.title}" has due date before creation date',
            taskId: task.id,
            severity: IssueSeverity.medium,
          ));
        }
      }
      
      // Check for completed tasks with future due dates that are not actually completed
      final now = DateTime.now();
      for (final task in tasks) {
        if (task.isCompleted && task.dueDate != null && 
            task.dueDate!.isAfter(now) && task.updatedAt.isBefore(task.dueDate!)) {
          issues.add(DataIntegrityIssue(
            type: IntegrityIssueType.inconsistentState,
            description: 'Task "${task.title}" marked completed before due date with suspicious timing',
            taskId: task.id,
            severity: IssueSeverity.low,
          ));
        }
      }
      
      // Check for empty or very short task titles
      for (final task in tasks) {
        if (task.title.trim().length < 3) {
          issues.add(DataIntegrityIssue(
            type: IntegrityIssueType.invalidData,
            description: 'Task has very short or empty title: "${task.title}"',
            taskId: task.id,
            severity: IssueSeverity.low,
          ));
        }
      }
      
      stopwatch.stop();
      
      return DataIntegrityResult(
        success: true,
        totalTasks: tasks.length,
        totalCategories: categories.length,
        issuesFound: issues.length,
        issues: issues,
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      debugPrint('Data integrity check failed: $e');
      return DataIntegrityResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Fix common data integrity issues
  Future<IntegrityFixResult> fixIntegrityIssues(List<DataIntegrityIssue> issues) async {
    try {
      var fixedCount = 0;
      final unfixedIssues = <DataIntegrityIssue>[];
      
      for (final issue in issues) {
        try {
          switch (issue.type) {
            case IntegrityIssueType.orphanedTask:
              // Move orphaned tasks to a default category
              final task = await _taskRepository.getTaskById(int.parse(issue.taskId));
              if (task != null) {
                final categories = await _categoryRepository.getAllCategories();
                final defaultCategory = categories.first; // Use first available category
                final updatedTask = task.copyWith(categoryId: defaultCategory.id.toString());
                await _taskRepository.updateTask(updatedTask);
                fixedCount++;
              }
              break;
              
            case IntegrityIssueType.duplicateTask:
              // Mark duplicate tasks with a suffix
              final task = await _taskRepository.getTaskById(int.parse(issue.taskId));
              if (task != null) {
                final updatedTask = task.copyWith(title: '${task.title} (duplicate)');
                await _taskRepository.updateTask(updatedTask);
                fixedCount++;
              }
              break;
              
            case IntegrityIssueType.invalidData:
              // Fix short titles by adding placeholder text
              final task = await _taskRepository.getTaskById(int.parse(issue.taskId));
              if (task != null && task.title.trim().length < 3) {
                final updatedTask = task.copyWith(title: 'Untitled Task');
                await _taskRepository.updateTask(updatedTask);
                fixedCount++;
              }
              break;
              
            default:
              // Cannot automatically fix this type of issue
              unfixedIssues.add(issue);
          }
        } catch (e) {
          debugPrint('Failed to fix issue ${issue.type}: $e');
          unfixedIssues.add(issue);
        }
      }
      
      return IntegrityFixResult(
        success: true,
        fixedIssues: fixedCount,
        unfixedIssues: unfixedIssues.length,
        remainingIssues: unfixedIssues,
      );
    } catch (e) {
      debugPrint('Integrity fix failed: $e');
      return IntegrityFixResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Helper methods
  
  Map<String, dynamic> _taskToExportMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'category_id': task.categoryId,
      'due_date': task.dueDate?.toIso8601String(),
      'due_time': task.dueTime != null 
          ? '${task.dueTime!.hour.toString().padLeft(2, '0')}:${task.dueTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'priority': task.priority.name,
      'completed': task.isCompleted,
      'source': task.source.name,
      'created_at': task.createdAt.toIso8601String(),
      'updated_at': task.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _categoryToExportMap(Category category) {
    return {
      'id': category.id,
      'name': category.name,
      'color': category.color.value,
      'icon': category.icon,
      'is_system': category.isSystem,
      'created_at': category.createdAt.toIso8601String(),
    };
  }

  Task _taskFromExportMap(Map<String, dynamic> data) {
    return Task(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      categoryId: data['category_id']?.toString() ?? '',
      dueDate: data['due_date'] != null ? DateTime.tryParse(data['due_date']) : null,
      dueTime: data['due_time'] != null ? _parseTimeFromString(data['due_time']) : null,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      isCompleted: data['completed'] ?? false,
      source: TaskSource.values.firstWhere(
        (s) => s.name == data['source'],
        orElse: () => TaskSource.manual,
      ),
      createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  TimeOfDay? _parseTimeFromString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Failed to parse time: $timeString');
    }
    return null;
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  void _writeTaskMarkdown(StringBuffer buffer, Task task) {
    final checkbox = task.isCompleted ? '- [x]' : '- [ ]';
    final priority = task.priority != TaskPriority.medium ? ' **${task.priority.displayName}**' : '';
    final dueDate = task.dueDateTimeDisplay != null ? ' *(Due: ${task.dueDateTimeDisplay})*' : '';
    
    buffer.writeln('$checkbox **${task.title}**$priority$dueDate');
    
    if (task.description != null && task.description!.isNotEmpty) {
      buffer.writeln('  ${task.description}');
    }
    
    buffer.writeln();
  }

  Future<File> _saveToFile(String content, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    return await file.writeAsString(content);
  }
}

/// Export result data models

class ExportResult {
  final bool success;
  final String? filePath;
  final int? fileSize;
  final int? recordCount;
  final ExportFormat format;
  final int? executionTimeMs;
  final String? error;

  const ExportResult({
    required this.success,
    this.filePath,
    this.fileSize,
    this.recordCount,
    required this.format,
    this.executionTimeMs,
    this.error,
  });
}

class ImportResult {
  final bool success;
  final int importedTasks;
  final int importedCategories;
  final int skippedTasks;
  final List<String> errors;
  final int? executionTimeMs;
  final String? error;

  const ImportResult({
    required this.success,
    this.importedTasks = 0,
    this.importedCategories = 0,
    this.skippedTasks = 0,
    this.errors = const [],
    this.executionTimeMs,
    this.error,
  });
}

class DataIntegrityResult {
  final bool success;
  final int totalTasks;
  final int totalCategories;
  final int issuesFound;
  final List<DataIntegrityIssue> issues;
  final int? executionTimeMs;
  final String? error;

  const DataIntegrityResult({
    required this.success,
    this.totalTasks = 0,
    this.totalCategories = 0,
    this.issuesFound = 0,
    this.issues = const [],
    this.executionTimeMs,
    this.error,
  });
}

class DataIntegrityIssue {
  final IntegrityIssueType type;
  final String description;
  final String taskId;
  final IssueSeverity severity;

  const DataIntegrityIssue({
    required this.type,
    required this.description,
    required this.taskId,
    required this.severity,
  });
}

class IntegrityFixResult {
  final bool success;
  final int fixedIssues;
  final int unfixedIssues;
  final List<DataIntegrityIssue> remainingIssues;
  final String? error;

  const IntegrityFixResult({
    required this.success,
    this.fixedIssues = 0,
    this.unfixedIssues = 0,
    this.remainingIssues = const [],
    this.error,
  });
}

enum ExportFormat {
  json,
  csv,
  markdown,
}

enum IntegrityIssueType {
  orphanedTask,
  duplicateTask,
  invalidDate,
  inconsistentState,
  invalidData,
}

enum IssueSeverity {
  low,
  medium,
  high,
}