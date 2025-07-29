import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:task_tracker_app/core/repositories/task_repository.dart';
import 'package:task_tracker_app/core/repositories/category_repository.dart';
import 'package:task_tracker_app/core/repositories/notification_repository.dart';
import 'package:task_tracker_app/core/services/database_service.dart';
import 'package:task_tracker_app/core/services/voice_service.dart';
import 'package:task_tracker_app/core/services/notification_service.dart';

// Generate mocks with: flutter packages pub run build_runner build
@GenerateMocks([
  TaskRepository,
  CategoryRepository,
  NotificationRepository,
  DatabaseService,
  VoiceService,
  NotificationService,
])
void main() {}