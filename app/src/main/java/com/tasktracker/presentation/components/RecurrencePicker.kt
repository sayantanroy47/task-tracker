package com.tasktracker.presentation.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
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
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.tasktracker.domain.model.RecurrenceType

@Composable
fun RecurrencePicker(
    currentRecurrence: RecurrenceType?,
    onRecurrenceSelected: (RecurrenceType?) -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    var selectedRecurrence by remember { mutableStateOf(currentRecurrence) }
    
    val recurrenceOptions = listOf(
        null to "No recurrence",
        RecurrenceType.DAILY to "Daily",
        RecurrenceType.WEEKLY to "Weekly", 
        RecurrenceType.MONTHLY to "Monthly"
    )

    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(
                text = "Task Recurrence",
                style = MaterialTheme.typography.headlineSmall
            )
        },
        text = {
            Column(
                modifier = Modifier.selectableGroup(),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                recurrenceOptions.forEach { (recurrence, label) ->
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .selectable(
                                selected = selectedRecurrence == recurrence,
                                onClick = { selectedRecurrence = recurrence },
                                role = Role.RadioButton
                            )
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        RadioButton(
                            selected = selectedRecurrence == recurrence,
                            onClick = null // handled by Row's selectable
                        )
                        Text(
                            text = label,
                            style = MaterialTheme.typography.bodyLarge
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
                Text("OK")
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
    recurrenceType: RecurrenceType?,
    onClearRecurrence: () -> Unit,
    modifier: Modifier = Modifier
) {
    recurrenceType?.let { type ->
        Row(
            modifier = modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Recurring task:",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
                Text(
                    text = formatRecurrenceType(type),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.secondary
                )
            }
            TextButton(onClick = onClearRecurrence) {
                Text("Clear")
            }
        }
    }
}

private fun formatRecurrenceType(recurrenceType: RecurrenceType): String {
    return when (recurrenceType) {
        RecurrenceType.DAILY -> "Repeats daily"
        RecurrenceType.WEEKLY -> "Repeats weekly"
        RecurrenceType.MONTHLY -> "Repeats monthly"
    }
}

@Preview(showBackground = true)
@Composable
fun RecurrencePickerPreview() {
    MaterialTheme {
        RecurrencePicker(
            currentRecurrence = RecurrenceType.DAILY,
            onRecurrenceSelected = {},
            onDismiss = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
fun RecurrenceDisplayPreview() {
    MaterialTheme {
        RecurrenceDisplay(
            recurrenceType = RecurrenceType.WEEKLY,
            onClearRecurrence = {}
        )
    }
}