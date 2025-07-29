# Chat Integration Feature

This document provides comprehensive information about the chat integration feature in the Task Tracker app, which allows users to extract tasks from messages shared from other apps like WhatsApp, Facebook Messenger, SMS, and other messaging platforms.

## Overview

The chat integration feature enables users to:
1. Share text from messaging apps to Task Tracker
2. Automatically extract actionable tasks from the shared content
3. Review and edit extracted tasks before creating them
4. Seamlessly integrate with the existing task management system

## Architecture

### Core Components

#### 1. Intent Handling (`IntentHandlerService`)
- **Platform**: Android & iOS
- **Purpose**: Receives shared text from external apps
- **Implementation**: 
  - Android: Method channels with native Java code
  - iOS: App delegate with Swift implementation
- **Features**:
  - Handles `ACTION_SEND` intents on Android
  - Supports iOS share extensions and URL schemes
  - Queues shared content when app is not active

#### 2. Message Parsing (`MessageParserService`)
- **Purpose**: Extracts tasks from natural language text
- **Features**:
  - Multiple parsing strategies for different message types
  - Confidence scoring for extracted tasks
  - Category suggestion based on content
  - Date/time extraction with natural language processing
  - Priority inference from urgency keywords

#### 3. UI Components (`ChatTaskReviewScreen`)
- **Purpose**: Allows users to review and edit extracted tasks
- **Features**:
  - Display original message context
  - Show extracted tasks with confidence indicators
  - Edit task details before creation
  - Batch approve/reject functionality
  - Visual feedback for different task qualities

#### 4. State Management (`ChatIntegrationProvider`)
- **Purpose**: Manages the chat integration workflow
- **States**:
  - `Idle`: Ready to process messages
  - `Processing`: Analyzing message content
  - `TasksExtracted`: Tasks found, awaiting user review
  - `NoTasksFound`: No actionable tasks detected
  - `Creating`: Creating tasks in the database
  - `Success`: Tasks created successfully
  - `Error`: Processing failed

## Parsing Strategies

### 1. Direct Requests
Identifies explicit requests and commands:
- Patterns: "Can you...", "Please...", "Remember to...", "Don't forget to..."
- Confidence: High (0.8-0.9)
- Examples: "Can you remind me to buy groceries tomorrow?"

### 2. Scheduled Items
Detects events with specific dates and times:
- Patterns: "Meeting at...", "Appointment on...", "Dinner tomorrow..."
- Confidence: High (0.8-0.9)
- Examples: "Doctor appointment next Tuesday at 2 PM"

### 3. Shopping Lists
Recognizes shopping and purchase items:
- Patterns: "Buy...", "Get...", "Pick up...", "We need..."
- Confidence: Medium-High (0.7-0.8)
- Examples: "Need to buy milk, bread, and eggs"

### 4. Appointments
Identifies medical, business, and personal appointments:
- Patterns: "Doctor", "Dentist", "Meeting", "Appointment"
- Confidence: High (0.8-0.9)
- Examples: "Schedule dentist cleaning next month"

### 5. Reminders
Detects explicit reminder requests:
- Patterns: "Remind me", "Don't let me forget", "Note to self"
- Confidence: Very High (0.9+)
- Examples: "Remind me to call mom tonight"

### 6. Deadlines
Identifies time-sensitive tasks with due dates:
- Patterns: "Due by...", "Deadline is...", "Must be done by..."
- Confidence: Very High (0.9+)
- Priority: Usually High or Urgent
- Examples: "Report due by Friday 5 PM"

### 7. Action Items
Recognizes general action items and to-dos:
- Patterns: "Action item:", "To do:", numbered/bulleted lists
- Confidence: Medium (0.6-0.7)
- Examples: "1. Send proposal 2. Schedule meeting"

### 8. Household Tasks
Specialized parsing for home maintenance and chores:
- Patterns: "Clean...", "Fix...", "Organize...", room-specific tasks
- Confidence: Medium-High (0.7-0.8)
- Category: Always "household"
- Examples: "Need to clean the kitchen and fix the faucet"

## Confidence Scoring

The confidence score (0.0-1.0) indicates how certain the parser is that the extracted text represents a genuine task:

### Factors that Increase Confidence:
- **Action Verbs** (+0.3): "buy", "call", "schedule", "pick up"
- **Time References** (+0.2): "tomorrow", "next week", "at 3 PM"
- **Request Keywords** (+0.25): "please", "can you", "remind me"
- **Specific Task Keywords** (+0.15): Context-specific action words
- **Urgency Indicators** (+0.1): "urgent", "asap", "immediately"
- **Personal Pronouns** (+0.05): "I need to", "you should"

### Factors that Decrease Confidence:
- **Generic Text** (-0.4): "ok", "thanks", "hello"
- **Very Short Text** (-0.3): Less than 3 characters
- **Question Indicators** (-0.2): "?", "what", "when", "how"
- **Excessive Length** (-0.1): More than 8 words might be noise

### Confidence Levels:
- **0.8-1.0**: Very High - Almost certainly a task
- **0.6-0.8**: High - Likely a task, good for auto-creation
- **0.4-0.6**: Medium - Possibly a task, needs user review
- **0.2-0.4**: Low - Unlikely to be a task
- **0.0-0.2**: Very Low - Probably not a task

## Category Suggestion

The system automatically suggests categories based on content keywords:

### Category Keywords:
- **Household**: grocery, cleaning, dishes, laundry, home, buy, shop, repair, fix
- **Health**: doctor, dentist, pharmacy, medication, exercise, gym, appointment
- **Work**: meeting, presentation, deadline, project, client, office, email
- **Family**: kids, school, parent, family, birthday, anniversary, dinner
- **Finance**: bill, payment, bank, insurance, tax, money, budget
- **Personal**: haircut, friend, hobby, lunch, coffee, book, movie

## Platform Integration

### Android Setup
1. **AndroidManifest.xml**: Intent filters for `ACTION_SEND` with `text/plain`
2. **MainActivity.java**: Handles incoming intents and forwards to Flutter
3. **IntentHandlerPlugin.java**: Method channel for Flutter communication

### iOS Setup
1. **Info.plist**: Document types and URL schemes configuration
2. **AppDelegate.swift**: Handles shared content and deep links
3. **Share Extension**: (Future enhancement) Dedicated share extension

## Usage Examples

### From WhatsApp:
1. Long press on a message containing tasks
2. Tap "Share" → "Task Tracker"
3. Review extracted tasks in the app
4. Edit if needed and create tasks

### From Any Text App:
1. Select text containing actionable items
2. Share to Task Tracker
3. Tasks are automatically extracted and presented for review

## Error Handling

### Common Errors:
- **No Tasks Found**: Message contains no actionable items
- **Parsing Errors**: Malformed or ambiguous text
- **Permission Errors**: App lacks necessary permissions
- **Network Errors**: (Future) When cloud features are added

### Error Recovery:
- User can manually create tasks from the original text
- Retry parsing with different strategies
- Fallback to basic task creation

## Testing

### Test Categories:
1. **Parsing Accuracy**: Verify correct task extraction
2. **Confidence Scoring**: Validate confidence calculations
3. **Category Suggestion**: Check appropriate category assignment
4. **Date/Time Parsing**: Test natural language date recognition
5. **Edge Cases**: Handle malformed input gracefully

### Test Data:
See `/lib/features/chat/examples/chat_test_examples.dart` for comprehensive test cases.

## Future Enhancements

### Planned Features:
1. **Machine Learning**: Improve parsing with user feedback
2. **Context Awareness**: Learn from user's task creation patterns
3. **Multi-language Support**: Support for non-English messages
4. **Advanced NLP**: Integration with cloud NLP services
5. **Batch Processing**: Handle multiple messages at once
6. **Smart Suggestions**: Proactive task suggestions from conversation context

### Performance Optimizations:
1. **Caching**: Cache parsing results for repeated messages
2. **Background Processing**: Parse large texts in background
3. **Incremental Parsing**: Parse messages as they arrive
4. **Compression**: Optimize message storage and transmission

## Security & Privacy

### Data Handling:
- **Local Processing**: All parsing happens on-device
- **No Cloud Storage**: Messages are not sent to external servers
- **Temporary Storage**: Shared content is cleared after processing
- **User Control**: Users review all extracted tasks before creation

### Permissions:
- **Android**: No special permissions required for shared text
- **iOS**: No special permissions required for shared text
- **Optional**: Notification permissions for reminders

## Troubleshooting

### Common Issues:
1. **App Not in Share Menu**: Check intent filters in AndroidManifest.xml
2. **No Tasks Extracted**: Message may not contain clear action items
3. **Wrong Categories**: Category keywords may need adjustment
4. **Date Parsing Issues**: Natural language date recognition limitations

### Debug Mode:
Enable debug logging to see parsing steps and confidence calculations.

## API Reference

### Key Classes:
- `IntentHandlerService`: Platform intent handling
- `MessageParserService`: NLP and task extraction
- `ChatIntegrationService`: Orchestrates the integration
- `ChatTaskReviewScreen`: UI for task review
- `ExtractedTask`: Model for parsed tasks
- `SharedContent`: Model for shared text content

### Key Methods:
- `parseMessageContent()`: Main parsing method
- `processSharedContent()`: Handle incoming shared text
- `confirmAndCreateTasks()`: Create approved tasks
- `handleSharedText()`: Process shared text directly

This chat integration feature significantly enhances the Task Tracker app's usability by allowing seamless task creation from everyday conversations and messages.