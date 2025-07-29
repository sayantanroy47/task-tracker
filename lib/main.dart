import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/constants.dart';
import 'core/navigation/navigation.dart';
import 'shared/providers/app_providers.dart';

void main() {
  runApp(const ProviderScope(child: TaskTrackerApp()));
}

class TaskTrackerApp extends ConsumerWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'Task Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Wrap with app initialization logic
        return _AppInitializer(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

/// App initializer widget that handles bootstrap logic
class _AppInitializer extends ConsumerStatefulWidget {
  final Widget child;
  
  const _AppInitializer({required this.child});

  @override
  ConsumerState<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<_AppInitializer> {
  @override
  void initState() {
    super.initState();
    // Initialize app state on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStateProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    
    return switch (appState) {
      AppStateLoading() => const AppLoadingScreen(),
      AppStateReady() => widget.child,
      AppStateError(:final message) => AppErrorScreen(message: message),
    };
  }
}


/// Loading screen shown during app initialization
class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Initializing Task Tracker...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when initialization fails
class AppErrorScreen extends ConsumerWidget {
  final String message;
  
  const AppErrorScreen({required this.message, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to initialize app',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(appStateProvider.notifier).initialize(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

