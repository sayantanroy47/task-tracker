# Quick Start Guide - Task Tracker App

## 🚀 How to Run the App (No Mobile Setup Required!)

### Option 1: Use the Run Script (Easiest)

**On Windows:**
```bash
# Double-click the file or run in Command Prompt:
run_app.bat
```

**On Mac/Linux:**
```bash
# Make executable and run:
chmod +x run_app.sh
./run_app.sh
```

The script will guide you through running the app in your browser or desktop!

---

### Option 2: Manual Commands

**If you have Flutter installed:**

```bash
# Run in web browser (Recommended - works without mobile setup)
flutter pub get
flutter run -d chrome

# OR run simple version
cp lib/main_simple.dart lib/main.dart
cp pubspec_simple.yaml pubspec.yaml
flutter pub get
flutter run -d chrome
```

---

### Option 3: Online Flutter (No Installation Required)

1. **Go to:** https://dartpad.dev/
2. **Click:** "New Flutter Project"
3. **Copy the code below** into DartPad:

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const SimpleTaskTrackerApp());
}

class SimpleTaskTrackerApp extends StatelessWidget {
  const SimpleTaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SimpleTaskScreen(),
    );
  }
}

class SimpleTaskScreen extends StatefulWidget {
  const SimpleTaskScreen({super.key});

  @override
  State<SimpleTaskScreen> createState() => _SimpleTaskScreenState();
}

class _SimpleTaskScreenState extends State<SimpleTaskScreen> {
  final List<SimpleTask> _tasks = [];
  final TextEditingController _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Tracker'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Add a new task...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Text(
                      'No tasks yet.\nAdd one above!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (value) {
                              setState(() {
                                _tasks[index] = task.copyWith(isCompleted: value ?? false);
                              });
                            },
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted ? Colors.grey : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _tasks.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _addTask() {
    final title = _titleController.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _tasks.add(SimpleTask(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          createdAt: DateTime.now(),
        ));
        _titleController.clear();
      });
    }
  }
}

class SimpleTask {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  const SimpleTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdAt,
  });

  SimpleTask copyWith({String? id, String? title, bool? isCompleted, DateTime? createdAt}) {
    return SimpleTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

4. **Click "Run"** to see the app in action!

---

### Option 4: Install Flutter for Full Features

If you want voice input, calendar, and advanced features:

**Install Flutter:**
1. **Download:** https://flutter.dev/docs/get-started/install
2. **Add to PATH:** Follow installation instructions
3. **Enable web:** `flutter config --enable-web`
4. **Run full app:** `flutter run -d chrome`

---

## 🎯 What You'll See

### Simple Version Features:
- ✅ **Add tasks** with text input
- ✅ **Mark tasks complete** with checkboxes  
- ✅ **Delete tasks** with trash button
- ✅ **Clean, responsive UI**
- ✅ **Works in any browser**

### Full Version Features (if Flutter installed):
- ✅ **Voice input** - "Remind me to buy groceries tomorrow"
- ✅ **Calendar view** - See tasks on calendar dates
- ✅ **Smart categories** - Auto-categorize tasks
- ✅ **Advanced UI** - Animations and gestures

---

## 🔧 Troubleshooting

**"Flutter not found"**
- Use Option 3 (Online DartPad) - no installation needed!

**"Chrome not found"**
- Install Google Chrome or use: `flutter run -d web-server`
- Then open: http://localhost:8080

**App doesn't load**
- Try the simple version: `cp lib/main_simple.dart lib/main.dart`
- Or use DartPad online

---

## 📱 What This Demonstrates

This task tracker showcases:
- **Flutter cross-platform development**
- **Modern UI/UX design patterns**  
- **State management with Riverpod**
- **Voice recognition integration**
- **Calendar and scheduling features**
- **Clean architecture principles**

Perfect for demonstrating Flutter's capabilities for building real-world productivity apps!