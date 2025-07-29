/// Comprehensive test examples for Natural Language Processing functionality
/// This file demonstrates the various types of voice input that the enhanced
/// NLP system can handle and parse effectively.

class NlpTestExamples {
  /// Test cases for date parsing functionality
  static const List<NlpTestCase> dateParsingExamples = [
    // Basic relative dates
    NlpTestCase(
      input: "Remind me to buy groceries tomorrow",
      expectedTitle: "Buy groceries",
      expectedDateType: DateType.tomorrow,
      expectedCategory: "household",
      expectedConfidence: 0.85,
    ),
    
    NlpTestCase(
      input: "Call doctor next Friday morning",
      expectedTitle: "Call doctor",
      expectedDateType: DateType.nextWeekday,
      expectedTimeType: TimeType.morning,
      expectedCategory: "health",
      expectedConfidence: 0.8,
    ),
    
    // Enhanced relative dates
    NlpTestCase(
      input: "Submit report the day after tomorrow at 2 PM",
      expectedTitle: "Submit report",
      expectedDateType: DateType.dayAfterTomorrow,
      expectedTimeType: TimeType.specificTime,
      expectedCategory: "work",
      expectedConfidence: 0.9,
    ),
    
    NlpTestCase(
      input: "Schedule vacation in 3 weeks",
      expectedTitle: "Schedule vacation",
      expectedDateType: DateType.inWeeks,
      expectedCategory: "personal",
      expectedConfidence: 0.8,
    ),
    
    // End of period patterns
    NlpTestCase(
      input: "Pay bills by end of month",
      expectedTitle: "Pay bills",
      expectedDateType: DateType.endOfMonth,
      expectedCategory: "finance",
      expectedConfidence: 0.75,
    ),
    
    NlpTestCase(
      input: "Complete project by end of this week",
      expectedTitle: "Complete project",
      expectedDateType: DateType.endOfWeek,
      expectedCategory: "work",
      expectedConfidence: 0.8,
    ),
  ];
  
  /// Test cases for time parsing functionality
  static const List<NlpTestCase> timeParsingExamples = [
    // 12-hour format
    NlpTestCase(
      input: "Meeting at 3:30 PM today",
      expectedTitle: "Meeting",
      expectedTimeType: TimeType.specificTime,
      expectedCategory: "work",
      expectedConfidence: 0.9,
    ),
    
    // Natural time expressions
    NlpTestCase(
      input: "Take medicine at noon",
      expectedTitle: "Take medicine",
      expectedTimeType: TimeType.noon,
      expectedCategory: "health",
      expectedConfidence: 0.9,
    ),
    
    // Enhanced time patterns
    NlpTestCase(
      input: "Dinner reservation at half past seven tonight",
      expectedTitle: "Dinner reservation",
      expectedTimeType: TimeType.halfPast,
      expectedDateType: DateType.tonight,
      expectedCategory: "personal",
      expectedConfidence: 0.85,
    ),
    
    NlpTestCase(
      input: "Gym workout early morning tomorrow",
      expectedTitle: "Gym workout",
      expectedTimeType: TimeType.earlyMorning,
      expectedDateType: DateType.tomorrow,
      expectedCategory: "health",
      expectedConfidence: 0.8,
    ),
  ];
  
  /// Test cases for priority extraction
  static const List<NlpTestCase> priorityExamples = [
    NlpTestCase(
      input: "Urgent: Call client about contract",
      expectedTitle: "Call client about contract",
      expectedPriority: "urgent",
      expectedCategory: "work",
      expectedConfidence: 0.85,
    ),
    
    NlpTestCase(
      input: "Important meeting with boss tomorrow",
      expectedTitle: "Meeting with boss",
      expectedPriority: "high",
      expectedDateType: DateType.tomorrow,
      expectedCategory: "work",
      expectedConfidence: 0.9,
    ),
    
    NlpTestCase(
      input: "Low priority task to organize closet",
      expectedTitle: "Organize closet",
      expectedPriority: "low",
      expectedCategory: "household",
      expectedConfidence: 0.8,
    ),
  ];
  
  /// Test cases for description extraction
  static const List<NlpTestCase> descriptionExamples = [
    NlpTestCase(
      input: "Schedule dentist appointment for routine cleaning and checkup next month",
      expectedTitle: "Schedule dentist appointment",
      expectedDescription: "for routine cleaning and checkup",
      expectedDateType: DateType.nextMonth,
      expectedCategory: "health",
      expectedConfidence: 0.85,
    ),
    
    NlpTestCase(
      input: "Buy groceries including milk, bread, and vegetables for weekend dinner tomorrow",
      expectedTitle: "Buy groceries",
      expectedDescription: "including milk, bread, and vegetables for weekend dinner",
      expectedDateType: DateType.tomorrow,
      expectedCategory: "household",
      expectedConfidence: 0.8,
    ),
  ];
  
  /// Test cases for category detection
  static const List<NlpTestCase> categoryExamples = [
    // Household tasks
    NlpTestCase(
      input: "Clean the kitchen and do laundry",
      expectedTitle: "Clean the kitchen and do laundry",
      expectedCategory: "household",
      expectedConfidence: 0.8,
    ),
    
    // Work tasks
    NlpTestCase(
      input: "Prepare presentation for client meeting",
      expectedTitle: "Prepare presentation for client meeting",
      expectedCategory: "work",
      expectedConfidence: 0.85,
    ),
    
    // Health tasks
    NlpTestCase(
      input: "Pick up prescription from pharmacy",
      expectedTitle: "Pick up prescription from pharmacy",
      expectedCategory: "health",
      expectedConfidence: 0.9,
    ),
    
    // Finance tasks
    NlpTestCase(
      input: "Transfer money to savings account",
      expectedTitle: "Transfer money to savings account",
      expectedCategory: "finance",
      expectedConfidence: 0.9,
    ),
    
    // Family tasks
    NlpTestCase(
      input: "Call mom for her birthday",
      expectedTitle: "Call mom for her birthday",
      expectedCategory: "family",
      expectedConfidence: 0.85,
    ),
  ];
  
  /// Complex test cases combining multiple features
  static const List<NlpTestCase> complexExamples = [
    NlpTestCase(
      input: "Urgent: Schedule important meeting with doctor about test results next Friday at 2 PM",
      expectedTitle: "Schedule meeting with doctor",
      expectedDescription: "about test results",
      expectedPriority: "urgent",
      expectedDateType: DateType.nextWeekday,
      expectedTimeType: TimeType.specificTime,
      expectedCategory: "health",
      expectedConfidence: 0.9,
    ),
    
    NlpTestCase(
      input: "Don't forget to pay mortgage and credit card bills by end of month before late fees",
      expectedTitle: "Pay mortgage and credit card bills",
      expectedDescription: "before late fees",
      expectedDateType: DateType.endOfMonth,
      expectedCategory: "finance",
      expectedConfidence: 0.85,
    ),
    
    NlpTestCase(
      input: "Prepare detailed project report for quarterly review meeting next Monday morning",
      expectedTitle: "Prepare detailed project report",
      expectedDescription: "for quarterly review meeting",
      expectedDateType: DateType.nextWeekday,
      expectedTimeType: TimeType.morning,
      expectedCategory: "work",
      expectedConfidence: 0.9,
    ),
  ];
  
  /// Edge cases and challenging scenarios
  static const List<NlpTestCase> edgeCaseExamples = [
    // Ambiguous time references
    NlpTestCase(
      input: "Call john this evening or tomorrow morning",
      expectedTitle: "Call john",
      expectedTimeType: TimeType.evening,
      expectedCategory: "personal",
      expectedConfidence: 0.6, // Lower confidence due to ambiguity
    ),
    
    // Multiple dates mentioned
    NlpTestCase(
      input: "Schedule vacation for next month but book flights today",
      expectedTitle: "Schedule vacation",
      expectedDateType: DateType.nextMonth, // Should pick the main action date
      expectedCategory: "personal",
      expectedConfidence: 0.7,
    ),
    
    // Informal/casual language
    NlpTestCase(
      input: "gotta remember to grab some groceries sometime tomorrow",
      expectedTitle: "Grab some groceries",
      expectedDateType: DateType.tomorrow,
      expectedCategory: "household",
      expectedConfidence: 0.7,
    ),
    
    // Very short input
    NlpTestCase(
      input: "gym tomorrow",
      expectedTitle: "Gym",
      expectedDateType: DateType.tomorrow,
      expectedCategory: "health",
      expectedConfidence: 0.6,
    ),
  ];
  
  /// Get all test examples grouped by category
  static Map<String, List<NlpTestCase>> getAllExamples() {
    return {
      'date_parsing': dateParsingExamples,
      'time_parsing': timeParsingExamples,
      'priority_extraction': priorityExamples,
      'description_extraction': descriptionExamples,
      'category_detection': categoryExamples,
      'complex_scenarios': complexExamples,
      'edge_cases': edgeCaseExamples,
    };
  }
}

/// Test case model for NLP functionality
class NlpTestCase {
  final String input;
  final String expectedTitle;
  final String? expectedDescription;
  final String? expectedPriority;
  final DateType? expectedDateType;
  final TimeType? expectedTimeType;
  final String? expectedCategory;
  final double expectedConfidence;
  
  const NlpTestCase({
    required this.input,
    required this.expectedTitle,
    this.expectedDescription,
    this.expectedPriority,
    this.expectedDateType,
    this.expectedTimeType,
    this.expectedCategory,
    required this.expectedConfidence,
  });
}

/// Enum for expected date types in test cases
enum DateType {
  today,
  tomorrow,
  dayAfterTomorrow,
  yesterday,
  tonight,
  thisWeekday,
  nextWeekday,
  nextWeek,
  nextMonth,
  nextYear,
  endOfWeek,
  endOfMonth,
  endOfYear,
  inDays,
  inWeeks,
  inMonths,
  thisWeekend,
  nextWeekend,
}

/// Enum for expected time types in test cases
enum TimeType {
  specificTime,
  noon,
  midnight,
  morning,
  afternoon,
  evening,
  night,
  earlyMorning,
  lateMorning,
  earlyAfternoon,
  lateAfternoon,
  earlyEvening,
  lateEvening,
  halfPast,
  quarterPast,
  quarterTo,
}