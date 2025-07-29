/// Examples and test cases for chat integration functionality
/// This file demonstrates how different types of messages get parsed into tasks

class ChatTestExamples {
  static const List<Map<String, dynamic>> testMessages = [
    // Direct requests
    {
      'message': 'Can you remind me to buy groceries tomorrow at 3 PM?',
      'expectedTasks': [
        {
          'title': 'Buy groceries',
          'category': 'household',
          'hasDate': true,
          'hasTime': true,
          'confidence': 0.9,
        }
      ]
    },
    
    // Shopping lists
    {
      'message': 'We need to buy milk, bread, and eggs today',
      'expectedTasks': [
        {'title': 'Buy milk', 'category': 'household'},
        {'title': 'Buy bread', 'category': 'household'},
        {'title': 'Buy eggs', 'category': 'household'},
      ]
    },
    
    // Appointments
    {
      'message': 'Doctor appointment next Tuesday at 10 AM',
      'expectedTasks': [
        {
          'title': 'Doctor appointment',
          'category': 'health',
          'hasDate': true,
          'hasTime': true,
        }
      ]
    },
    
    // Reminders
    {
      'message': 'Remind me to call mom this evening',
      'expectedTasks': [
        {
          'title': 'Call mom',
          'category': 'family',
          'hasTime': true,
        }
      ]
    },
    
    // Deadlines
    {
      'message': 'The project report is due by Friday 5 PM',
      'expectedTasks': [
        {
          'title': 'Project report',
          'category': 'work',
          'priority': 'high',
          'hasDate': true,
          'hasTime': true,
        }
      ]
    },
    
    // Household tasks
    {
      'message': 'Need to clean the kitchen and fix the leaky faucet',
      'expectedTasks': [
        {'title': 'Clean the kitchen', 'category': 'household'},
        {'title': 'Fix the leaky faucet', 'category': 'household'},
      ]
    },
    
    // Action items from meetings
    {
      'message': '''Action items from today's meeting:
      1. Send proposal to client
      2. Schedule follow-up meeting
      3. Update project timeline''',
      'expectedTasks': [
        {'title': 'Send proposal to client', 'category': 'work'},
        {'title': 'Schedule follow-up meeting', 'category': 'work'},
        {'title': 'Update project timeline', 'category': 'work'},
      ]
    },
    
    // Complex message with multiple tasks and priorities
    {
      'message': 'URGENT: Submit tax documents by tomorrow noon, also remember to pick up dry cleaning and schedule dentist appointment next week',
      'expectedTasks': [
        {
          'title': 'Submit tax documents',
          'category': 'finance',
          'priority': 'urgent',
          'hasDate': true,
          'hasTime': true,
        },
        {
          'title': 'Pick up dry cleaning',
          'category': 'personal',
        },
        {
          'title': 'Schedule dentist appointment',
          'category': 'health',
          'hasDate': true,
        }
      ]
    },
    
    // No tasks expected
    {
      'message': 'Hi, how are you? Hope you have a great day!',
      'expectedTasks': []
    },
    
    // Question (should have low confidence)
    {
      'message': 'What time is the meeting tomorrow?',
      'expectedTasks': []
    },
  ];
  
  /// Get a test message by index
  static Map<String, dynamic>? getTestMessage(int index) {
    if (index >= 0 && index < testMessages.length) {
      return testMessages[index];
    }
    return null;
  }
  
  /// Get all test messages with direct requests
  static List<Map<String, dynamic>> getDirectRequestExamples() {
    return testMessages.where((example) {
      final message = example['message'] as String;
      return message.toLowerCase().contains('can you') ||
             message.toLowerCase().contains('remind me') ||
             message.toLowerCase().contains('please');
    }).toList();
  }
  
  /// Get all test messages with time references
  static List<Map<String, dynamic>> getTimeReferenceExamples() {
    return testMessages.where((example) {
      final tasks = example['expectedTasks'] as List;
      return tasks.any((task) => task['hasTime'] == true || task['hasDate'] == true);
    }).toList();
  }
  
  /// Get all test messages with shopping lists
  static List<Map<String, dynamic>> getShoppingListExamples() {
    return testMessages.where((example) {
      final tasks = example['expectedTasks'] as List;
      return tasks.any((task) => 
        task['category'] == 'household' && 
        (task['title'] as String).toLowerCase().contains('buy'));
    }).toList();
  }
  
  /// Get all test messages with appointments
  static List<Map<String, dynamic>> getAppointmentExamples() {
    return testMessages.where((example) {
      final message = example['message'] as String;
      return message.toLowerCase().contains('appointment') ||
             message.toLowerCase().contains('meeting') ||
             message.toLowerCase().contains('doctor') ||
             message.toLowerCase().contains('dentist');
    }).toList();
  }
}

/// Sample chat messages for different apps
class SampleChatMessages {
  static const whatsappMessages = [
    "Don't forget to pick up the kids from soccer practice at 4 PM",
    "Grocery list: milk, bread, bananas, chicken, rice",
    "Can you please call the insurance company tomorrow morning?",
    "Dinner reservation for 2 at 7 PM on Saturday at Luigi's",
    "Reminder: pay electricity bill by 15th",
  ];
  
  static const facebookMessages = [
    "Birthday party planning meeting this Tuesday at 6 PM",
    "Need to buy decorations and cake for the event",
    "Don't forget to RSVP for Sarah's wedding by next Friday",
    "Book flight tickets for vacation - check prices this weekend",
    "Team lunch tomorrow at noon - Mexican restaurant downtown",
  ];
  
  static const smsMessages = [
    "Appointment confirmed: Dr. Smith, Thursday 2:30 PM",
    "Car service due next week - call garage to schedule",
    "Meeting with client moved to Monday 10 AM",
    "Pick up prescription from pharmacy after work",
    "Parent-teacher conference next Tuesday 3 PM",
  ];
  
  static const slackMessages = [
    "Action item: Review PR #123 by EOD Friday",
    "Schedule standup for Monday 9 AM with the team",
    "Deadline reminder: Budget proposal due Wednesday",
    "Book conference room for client presentation next Thursday",
    "Update documentation before quarterly review",
  ];
}

/// Confidence scoring test cases
class ConfidenceTestCases {
  static const List<Map<String, dynamic>> confidenceTests = [
    // High confidence tasks
    {'message': 'Remind me to buy groceries tomorrow', 'expectedConfidence': 0.8},
    {'message': 'Call doctor to schedule appointment', 'expectedConfidence': 0.75},
    {'message': 'Pick up dry cleaning after work', 'expectedConfidence': 0.8},
    
    // Medium confidence tasks
    {'message': 'Meeting with client next week', 'expectedConfidence': 0.6},
    {'message': 'Need to organize files', 'expectedConfidence': 0.5},
    {'message': 'Check email later', 'expectedConfidence': 0.5},
    
    // Low confidence tasks
    {'message': 'What time is the meeting?', 'expectedConfidence': 0.3},
    {'message': 'Maybe we should talk later', 'expectedConfidence': 0.3},
    {'message': 'Good morning!', 'expectedConfidence': 0.1},
    
    // Should not be tasks
    {'message': 'How are you?', 'expectedConfidence': 0.0},
    {'message': 'Thanks for the help!', 'expectedConfidence': 0.0},
    {'message': 'See you later', 'expectedConfidence': 0.0},
  ];
}

/// Category suggestion test cases
class CategoryTestCases {
  static const List<Map<String, dynamic>> categoryTests = [
    // Household
    {'message': 'Buy groceries and clean the house', 'expectedCategory': 'household'},
    {'message': 'Fix the broken faucet', 'expectedCategory': 'household'},
    {'message': 'Do the laundry', 'expectedCategory': 'household'},
    
    // Work
    {'message': 'Meeting with client tomorrow', 'expectedCategory': 'work'},
    {'message': 'Prepare presentation for boss', 'expectedCategory': 'work'},
    {'message': 'Send email to project team', 'expectedCategory': 'work'},
    
    // Health
    {'message': 'Doctor appointment next week', 'expectedCategory': 'health'},
    {'message': 'Pick up prescription from pharmacy', 'expectedCategory': 'health'},
    {'message': 'Schedule dentist cleaning', 'expectedCategory': 'health'},
    
    // Finance
    {'message': 'Pay credit card bill', 'expectedCategory': 'finance'},
    {'message': 'Review bank statements', 'expectedCategory': 'finance'},
    {'message': 'Call insurance company', 'expectedCategory': 'finance'},
    
    // Family
    {'message': 'Pick up kids from school', 'expectedCategory': 'family'},
    {'message': 'Plan birthday party for mom', 'expectedCategory': 'family'},
    {'message': 'Family dinner on Sunday', 'expectedCategory': 'family'},
    
    // Personal
    {'message': 'Get haircut this weekend', 'expectedCategory': 'personal'},
    {'message': 'Meet friend for coffee', 'expectedCategory': 'personal'},
    {'message': 'Read new book', 'expectedCategory': 'personal'},
  ];
}