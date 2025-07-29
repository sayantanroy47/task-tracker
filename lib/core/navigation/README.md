# Navigation Framework Documentation

This directory contains the complete navigation framework for the Task Tracker app, implemented using `go_router` and integrated with Riverpod state management.

## Architecture Overview

The navigation system is designed with the following principles:
- **Declarative routing** using go_router
- **Type-safe navigation** with route constants and helpers
- **Deep linking support** for both app schemes and web URLs
- **State management integration** with Riverpod providers
- **Navigation guards** and middleware for enhanced control
- **Custom transitions** for better user experience

## Files Structure

### Core Files

- **`app_router.dart`** - Main router configuration and route definitions
- **`app_routes.dart`** - Route constants and path definitions
- **`navigation_service.dart`** - Service class for programmatic navigation
- **`navigation_middleware.dart`** - Middleware for navigation guards and analytics
- **`navigation_helper.dart`** - Utility methods for common navigation patterns
- **`navigation.dart`** - Barrel export file

## Route Structure

### Main Routes (with bottom navigation)
- `/` - Home/Tasks screen
- `/calendar` - Calendar view
- `/settings` - Settings screen

### Modal Routes (full-screen, no bottom navigation)
- `/task/new` - Task creation form
- `/task/:id/edit` - Task editing form
- `/voice` - Voice input screen

## Usage Examples

### Basic Navigation

```dart
// Using navigation service
final navigationService = ref.read(navigationServiceProvider);
navigationService.goToVoice(context);

// Using context extensions
context.go(AppRoutes.calendar);
context.push(AppRoutes.taskNew);

// Using navigation helper
NavigationHelper.createTask(context, title: 'Sample Task');
NavigationHelper.editTask(context, taskId);
```

### Deep Linking

The app supports two deep linking schemes:

#### App Scheme (tasktracker://)
```
tasktracker://task/new?title=Sample%20Task
tasktracker://voice
tasktracker://calendar?date=2024-01-15
tasktracker://task/123/edit
```

#### Web Scheme (https://tasktracker.app)
```
https://tasktracker.app/app/task/new
https://tasktracker.app/app/voice
https://tasktracker.app/app/calendar
```

### Navigation with Parameters

```dart
// Create task with pre-filled data
NavigationHelper.createTask(
  context,
  title: 'Meeting preparation',
  categoryId: 'work',
  dueDate: DateTime.now().add(Duration(days: 1)),
);

// Open calendar with specific date
NavigationHelper.openCalendar(
  context,
  focusDate: DateTime(2024, 1, 15),
);
```

### Navigation Guards

The middleware system supports:
- Global redirects (e.g., onboarding flow)
- Route validation
- Navigation analytics
- Error handling

```dart
// Custom redirect logic in navigation_middleware.dart
String? handleRedirect(GoRouterState state) {
  // Example: Redirect legacy routes
  if (state.uri.path == '/tasks') {
    return AppRoutes.home;
  }
  return null;
}
```

## Custom Transitions

The framework includes custom page transitions:

- **Main routes**: Fade transition for smooth navigation between tabs
- **Modal routes**: Slide transition from bottom for form screens

## Integration with Riverpod

### Router Provider
```dart
final routerProvider = Provider<GoRouter>((ref) {
  final middleware = ref.read(navigationMiddlewareProvider);
  return GoRouter(/* configuration */);
});
```

### Navigation State Tracking
```dart
final currentRouteProvider = StateProvider<String>((ref) => AppRoutes.home);
final navigationHistoryProvider = StateProvider<List<String>>((ref) => []);
```

## Error Handling

The navigation system includes:
- Custom error screens for invalid routes
- Fallback navigation to home screen
- Deep link validation
- Navigation error logging

## Performance Considerations

- **Lazy loading**: Route builders are only called when needed
- **State preservation**: Shell routes maintain state between tab switches
- **Memory management**: Proper disposal of navigation controllers

## Testing

When testing navigation:

1. Use `NavigationHelper` methods for consistent behavior
2. Mock the `navigationServiceProvider` for unit tests
3. Test deep link handling with various URL formats
4. Verify route parameters are correctly parsed

## Future Enhancements

Potential improvements to consider:
- Route-based permissions/authentication
- Navigation analytics integration
- Offline navigation caching
- Dynamic route generation
- A/B testing for navigation flows

## Troubleshooting

### Common Issues

1. **Route not found**: Check route definitions in `app_routes.dart`
2. **Parameters not passed**: Verify parameter names match route definitions
3. **Deep links not working**: Check Android manifest intent filters
4. **Navigation state lost**: Ensure providers are properly scoped

### Debug Tools

Enable router debugging:
```dart
GoRouter(
  debugLogDiagnostics: true,
  // ... other configuration
)
```

## Best Practices

1. **Use constants**: Always use `AppRoutes` constants instead of hardcoded strings
2. **Type safety**: Use helper methods that validate parameters
3. **Error handling**: Always provide fallback routes
4. **User experience**: Use appropriate transitions for different navigation types
5. **Testing**: Write tests for critical navigation flows