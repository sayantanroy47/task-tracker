package com.tasktracker.presentation.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.selectable
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tasktracker.domain.model.RecurrenceType

@Composable
fun RecurrencePicker(
    currentRecurrence: RecurrenceType?,
    onRecurrenceSelected: (RecurrenceType?) -> Unit,
    onDismiss: () -> Unit
) {
    var selectedRecurrence by remember { mutableStateOf(currentRecurrence) }
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("Set Recurrence")
        },
        text = {
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text("Select recurrence pattern:")
                
                // None option
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .selectable(
                            selected = selectedRecurrence == null,
                            onClick = { selectedRecurrence = null }
                        )
                        .padding(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    RadioButton(
                        selected = selectedRecurrence == null,
                        onClick = { selectedRecurrence = null }
                    )
                    Text(
                        text = "None",
                        modifier = Modifier.padding(start = 8.dp)
                    )
                }
                
                // Recurrence options
                RecurrenceType.values().forEach { recurrence ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .selectable(
                                selected = selectedRecurrence == recurrence,
                                onClick = { selectedRecurrence = recurrence }
                            )
                            .padding(8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        RadioButton(
                            selected = selectedRecurrence == recurrence,
                            onClick = { selectedRecurrence = recurrence }
                        )
                        Text(
                            text = when (recurrence) {
                                RecurrenceType.DAILY -> "Daily"
                                RecurrenceType.WEEKLY -> "Weekly"
                                RecurrenceType.MONTHLY -> "Monthly"
                            },
                            modifier = Modifier.padding(start = 8.dp)
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onRecurrenceSelected(selectedRecurrence)
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
fun RecurrenceDisplay(
    recurrenceType: RecurrenceType,
    onClearRecurrence: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(8.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = "Recurrence: ${when (recurrenceType) {
                RecurrenceType.DAILY -> "Daily"
                RecurrenceType.WEEKLY -> "Weekly"
                RecurrenceType.MONTHLY -> "Monthly"
            }}",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.secondary
        )
        
        TextButton(onClick = onClearRecurrence) {
            Text("Clear")
        }
    }
}