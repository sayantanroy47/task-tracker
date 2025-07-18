package com.tasktracker.presentation.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tasktracker.presentation.components.glassmorphism.GlassButton
import java.util.Calendar

@Composable
fun ReminderTimePicker(
    onTimeSelected: (Long) -> Unit,
    onDismiss: () -> Unit
) {
    var selectedHour by remember { mutableStateOf(12) }
    var selectedMinute by remember { mutableStateOf(0) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("Set Reminder Time")
        },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Text("Select time for reminder:")
                
                // Simple time picker (in a real app, you'd use a proper time picker)
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    Column {
                        Text("Hour: $selectedHour")
                        GlassButton(
                            onClick = { selectedHour = (selectedHour + 1) % 24 }
                        ) {
                            Text("+")
                        }
                        GlassButton(
                            onClick = { selectedHour = if (selectedHour == 0) 23 else selectedHour - 1 }
                        ) {
                            Text("-")
                        }
                    }
                    
                    Column {
                        Text("Minute: $selectedMinute")
                        GlassButton(
                            onClick = { selectedMinute = (selectedMinute + 15) % 60 }
                        ) {
                            Text("+15")
                        }
                        GlassButton(
                            onClick = { selectedMinute = if (selectedMinute == 0) 45 else selectedMinute - 15 }
                        ) {
                            Text("-15")
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val calendar = Calendar.getInstance().apply {
                        set(Calendar.HOUR_OF_DAY, selectedHour)
                        set(Calendar.MINUTE, selectedMinute)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                        
                        // If the time is in the past, set it for tomorrow
                        if (timeInMillis <= System.currentTimeMillis()) {
                            add(Calendar.DAY_OF_MONTH, 1)
                        }
                    }
                    onTimeSelected(calendar.timeInMillis)
                }
            ) {
                Text("Set")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
fun ReminderTimeDisplay(
    reminderTime: Long,
    onClearReminder: () -> Unit
) {
    val calendar = Calendar.getInstance().apply {
        timeInMillis = reminderTime
    }
    
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = "Reminder: ${calendar.get(Calendar.HOUR_OF_DAY)}:${String.format("%02d", calendar.get(Calendar.MINUTE))}",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.primary
        )
        
        TextButton(onClick = onClearReminder) {
            Text("Clear")
        }
    }
}