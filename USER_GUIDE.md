# Task Tracker User Guide

Welcome to the Task Tracker app! This comprehensive guide will help you master all the features and get the most out of your voice-powered task management experience.

## 📱 Getting Started

### First Launch
When you first open Task Tracker, the app will:
1. **Initialize the database** with default categories
2. **Request microphone permissions** for voice input
3. **Set up notification permissions** for reminders
4. **Display the main task screen** with sample tasks (optional)

### Main Interface Overview
- **Task List**: Central view showing all your tasks
- **Voice Button**: Floating microphone icon for voice input
- **Search Bar**: Quick search and filter access
- **Navigation Bar**: Switch between Tasks, Calendar, and Settings
- **Filter Bar**: Quick access to task filters (All, Pending, Overdue, etc.)

## 🎤 Voice Input Mastery

### Basic Voice Commands
The app understands natural language. Simply speak as you would to a friend:

#### Task Creation Examples
```
"Remind me to buy groceries tomorrow at 3 PM"
"Call the dentist for a checkup next Friday morning"
"Pay the electricity bill by the end of this month"
"Important: Submit the quarterly report tomorrow"
"Buy mom's birthday gift this weekend"
```

#### What the App Extracts
- **Task Title**: Main action (e.g., "buy groceries")
- **Date**: When it's due (e.g., "tomorrow", "next Friday")
- **Time**: Specific time if mentioned (e.g., "3 PM", "morning")
- **Priority**: Urgency keywords (e.g., "important", "urgent", "ASAP")
- **Category**: Auto-suggested based on content
- **Description**: Additional details for longer inputs

### Advanced Voice Patterns

#### Date Recognition (50+ Patterns)
- **Relative dates**: "tomorrow", "next week", "in 3 days"
- **Specific dates**: "January 15th", "December 25th"
- **End of periods**: "end of this month", "beginning of next year"
- **Weekdays**: "this Monday", "next Friday"
- **Holidays**: "before Christmas", "after New Year"
- **Seasons**: "next spring", "this summer"

#### Time Recognition
- **12-hour format**: "3 PM", "9:30 AM"
- **24-hour format**: "15:30", "09:00"
- **Natural expressions**: "noon", "midnight", "morning", "evening"
- **Approximate times**: "around 2 PM", "about 10 AM"
- **Relative times**: "half past 3", "quarter to 5"

#### Priority Keywords
- **Urgent**: "urgent", "ASAP", "immediately", "critical", "emergency"
- **High**: "important", "priority", "crucial", "vital", "essential"
- **Medium**: "normal", "regular", "standard"
- **Low**: "low", "minor", "optional", "when possible"

#### Category Detection
The app automatically suggests categories based on keywords:
- **Personal**: "read", "book", "hobby", "learn", "relax"
- **Household**: "clean", "groceries", "cooking", "laundry", "repairs"
- **Work**: "meeting", "deadline", "email", "presentation", "project"
- **Family**: "mom", "dad", "kids", "birthday", "anniversary"
- **Health**: "doctor", "dentist", "medicine", "exercise", "gym"
- **Finance**: "pay", "bill", "bank", "budget", "tax", "insurance"

### Voice Input Tips
1. **Speak clearly** in a normal pace
2. **Use natural language** - don't try to speak like a robot
3. **Include context** - the more details, the better the parsing
4. **Check suggestions** - always review before confirming
5. **Edit if needed** - tap any field to modify the parsed results

## 📅 Calendar Integration

### Calendar Views
Switch between three different calendar views:

#### Month View
- **Overview**: See the entire month with task indicators
- **Task Dots**: Colored dots show tasks on specific dates
- **Navigation**: Swipe left/right or use arrow buttons
- **Today Button**: Quickly jump to the current date

#### Week View
- **Detailed View**: See 7 days with task details
- **Time Slots**: View tasks with specific times
- **Quick Navigation**: Scroll through weeks

#### Agenda View
- **Chronological List**: Tasks organized by date
- **Upcoming Focus**: See what's coming up in order
- **Date Sections**: Clear separation between different days

### Creating Tasks from Calendar
1. **Tap any date** to select it
2. **Use the floating action button** (+) to create a task
3. **Date is pre-filled** with your selected date
4. **Add details** manually or use voice input

### Calendar Features
- **Task Indicators**: Color-coded dots based on task categories
- **Multiple Tasks**: Stacked dots show multiple tasks on one day
- **Overdue Highlighting**: Different colors for past due tasks
- **Completion Status**: Completed tasks shown differently

## 💬 Chat Integration

### Setting Up Chat Integration
The app can extract tasks from messages shared from other apps:

#### Supported Apps
- WhatsApp
- Facebook Messenger
- SMS/Text Messages
- Telegram
- Any app that supports text sharing

### How to Use Chat Integration
1. **Open your messaging app** (WhatsApp, Facebook, etc.)
2. **Find a message** with task-like content
3. **Long-press the message** and select "Share"
4. **Choose "Task Tracker"** from the share menu
5. **Review extracted tasks** in the Task Review screen
6. **Approve or edit** tasks before adding them

### Message Parsing Examples
The app can extract tasks from messages like:
```
"Don't forget to pick up groceries tomorrow"
→ Task: "Pick up groceries", Due: Tomorrow

"Meeting with client at 2 PM Friday"
→ Task: "Meeting with client", Due: Friday at 2 PM

"Reminder: Pay rent by the 1st of next month"
→ Task: "Pay rent", Due: 1st of next month
```

### Task Review Screen
When you share text from another app:
1. **Parsed Tasks**: Shows what the app extracted
2. **Confidence Scores**: How sure the app is about each detail
3. **Edit Options**: Modify any extracted information
4. **Batch Approval**: Accept multiple tasks at once
5. **Source Tracking**: Remember which app the task came from

## 🔍 Search and Filtering

### Quick Search
Use the search bar at the top of the main screen:
- **Type keywords** to find tasks by title or description
- **Get suggestions** as you type
- **See highlighted results** with matched text emphasized

### Advanced Filtering
Tap the filter icon to access advanced options:

#### Filter Categories
- **Status**: All, Pending, Completed, Overdue
- **Priority**: Low, Medium, High, Urgent
- **Category**: Personal, Household, Work, Family, Health, Finance
- **Source**: Manual, Voice, Chat
- **Date Range**: Custom date range picker
- **Has Reminder**: Tasks with or without reminders

#### Quick Filter Buttons
- **All**: Show everything
- **Pending**: Incomplete tasks only
- **Overdue**: Past due tasks
- **Today**: Due today
- **Tomorrow**: Due tomorrow
- **Completed**: Finished tasks
- **High Priority**: Important/urgent tasks

### Search Tips
1. **Use partial words** - "groc" will find "groceries"
2. **Search descriptions** - the app searches both titles and descriptions
3. **Combine filters** - use multiple criteria together
4. **Save frequent searches** - bookmark commonly used filters
5. **Clear filters** - tap "Clear" to reset all filters

### Smart Suggestions
The search bar provides intelligent suggestions:
- **Recent tasks** - tasks you've worked with recently
- **Categories** - suggest "Category: Work" for category filtering
- **Quick filters** - suggest "Overdue tasks" for status filtering
- **Auto-complete** - finish your typing based on existing tasks

## 🎨 Customization and Settings

### Theme Settings
- **Light Mode**: Clean, bright interface
- **Dark Mode**: Easy on the eyes for low-light use
- **System Theme**: Automatically follows your device setting

### Notification Preferences
Configure how and when you receive reminders:

#### Reminder Intervals
- **1 day before**: Get notified 24 hours in advance
- **12 hours before**: Half-day advance notice
- **6 hours before**: Quarter-day advance notice
- **1 hour before**: Last-minute reminder

#### Notification Settings
- **Notification Actions**: Complete, snooze, or reschedule from notifications
- **Do Not Disturb**: Respect system quiet hours
- **Sound & Vibration**: Customize notification alerts
- **Badges**: Show unread task count on app icon

### Category Management
- **Default Categories**: Personal, Household, Work, Family, Health, Finance
- **Custom Categories**: Add your own categories (coming soon)
- **Category Colors**: Each category has a unique color
- **Icons**: Visual indicators for easy recognition

## 📊 Analytics and Insights

### Task Analytics
View your productivity patterns and trends:

#### Completion Statistics
- **Completion Rate**: Percentage of tasks you complete
- **Weekly Trends**: See how you perform week by week
- **Category Performance**: Which types of tasks you complete most
- **Source Analysis**: Performance by task creation method (voice, manual, chat)

#### Productivity Insights
- **Best Days**: Which days of the week you're most productive
- **Peak Hours**: What times you complete the most tasks
- **Overdue Patterns**: Common reasons tasks become overdue
- **Habit Tracking**: Regular tasks and their completion patterns

### Data Export
Back up your data or analyze it externally:
- **JSON Format**: Complete data with all fields
- **CSV Format**: Spreadsheet-compatible format
- **Markdown Format**: Human-readable text format
- **Data Integrity**: Automatic validation and error checking

## 🔧 Troubleshooting

### Voice Input Issues
**Problem**: Voice input not working
- **Check permissions**: Ensure microphone access is granted
- **Test microphone**: Try recording in another app
- **Restart app**: Close and reopen Task Tracker
- **Check language**: Voice recognition works best in English

**Problem**: Poor recognition accuracy
- **Speak clearly**: Use normal pace and pronunciation
- **Reduce background noise**: Find a quiet environment
- **Use shorter phrases**: Break complex tasks into simpler parts
- **Check suggestions**: Review and edit parsed results

### Calendar Issues
**Problem**: Tasks not showing on calendar
- **Check date**: Ensure tasks have due dates set
- **Refresh view**: Pull down to refresh the calendar
- **Switch views**: Try different calendar view modes
- **Restart app**: Close and reopen if problems persist

### Notification Issues
**Problem**: Not receiving reminders
- **Check permissions**: Ensure notification access is granted
- **Check settings**: Verify reminder intervals are set
- **Check Do Not Disturb**: Make sure it's not blocking notifications
- **Battery optimization**: Disable battery optimization for the app

### Performance Issues
**Problem**: App running slowly
- **Restart app**: Close and reopen Task Tracker
- **Clear cache**: Use system settings to clear app cache
- **Update app**: Make sure you have the latest version
- **Free storage**: Ensure device has adequate free space

### Data Issues
**Problem**: Tasks missing or corrupted
- **Use export**: Regularly export your data as backup
- **Check integrity**: The app has built-in data validation
- **Restore from backup**: Import previously exported data
- **Contact support**: Report persistent data issues

## 🚀 Pro Tips and Best Practices

### Voice Input Mastery
1. **Be specific with dates**: "Next Tuesday" is better than "soon"
2. **Include priority keywords**: Use "important" or "urgent" when relevant
3. **Add context**: "Doctor appointment for annual checkup" vs. just "doctor"
4. **Use natural language**: Speak as you would to a friend
5. **Review before confirming**: Always check the parsed results

### Task Organization
1. **Use categories consistently**: Keep similar tasks in the same category
2. **Set realistic due dates**: Don't overcommit yourself
3. **Break down big tasks**: Split complex projects into smaller tasks
4. **Use descriptions**: Add extra details for future reference
5. **Regular reviews**: Check your task list daily

### Calendar Best Practices
1. **Time-block important tasks**: Set specific times for critical tasks
2. **Use different views**: Month for overview, week for details
3. **Color-code categories**: Use category colors to organize visually
4. **Plan ahead**: Use the calendar to schedule future tasks
5. **Review weekly**: Check upcoming tasks every Sunday

### Productivity Tips
1. **Process chat integrations**: Review shared tasks promptly
2. **Use quick filters**: Find specific tasks faster
3. **Set reminders strategically**: Choose intervals that work for you
4. **Export regularly**: Back up your data monthly
5. **Analyze patterns**: Use analytics to improve your habits

## 📞 Support and Feedback

### Getting Help
- **In-app help**: Check tooltips and help text throughout the app
- **This guide**: Refer back to this comprehensive guide
- **Video tutorials**: Watch feature demonstrations (coming soon)
- **Community forum**: Connect with other users (coming soon)

### Reporting Issues
- **Bug reports**: Use the feedback option in settings
- **Feature requests**: Share ideas for new features
- **Performance issues**: Report slowdowns or crashes
- **Data problems**: Alert us to any data integrity issues

### Contact Information
- **Email**: support@tasktracker.app
- **GitHub Issues**: For technical problems and feature requests
- **App Store Reviews**: Share your overall experience

---

## 🎉 Congratulations!

You now know how to use all the powerful features of Task Tracker. With voice input, calendar integration, chat parsing, and smart search, you have everything you need to stay organized and never forget important tasks again.

Remember: The app is designed to adapt to your natural speaking patterns and workflow. The more you use it, the better it becomes at understanding your preferences and helping you stay productive.

**Happy task tracking!** 🚀