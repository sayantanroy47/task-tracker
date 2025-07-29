/// Calendar feature module
///
/// This module provides comprehensive calendar integration for the task tracker app.
/// It includes calendar widgets, date/time utilities, voice integration, and state management.
///
/// Key Features:
/// - Interactive calendar widget with task indicators
/// - Natural language date/time parsing
/// - Voice input integration with immediate calendar updates
/// - Timezone-aware date handling
/// - Comprehensive calendar state management
library;

// Core calendar components
export 'calendar_screen.dart';
export 'widgets/calendar_widget.dart';

// State management
export 'providers/calendar_providers.dart';

// Utilities
export 'utils/date_time_utils.dart';

// Services
export 'services/voice_calendar_integration.dart';
