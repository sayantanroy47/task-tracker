package com.tasktracker.presentation.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Snackbar
import androidx.compose.material3.SnackbarData
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.tasktracker.domain.model.Task

@Composable
fun UndoSnackbar(
    task: Task,
    onUndo: () -> Unit,
    onDismiss: () -> Unit,
    modifier: Modifier = Modifier
) {
    Snackbar(
        modifier = modifier,
        action = {
            TextButton(onClick = onUndo) {
                Text(
                    text = "UNDO",
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Bold
                )
            }
        },
        dismissAction = {
            TextButton(onClick = onDismiss) {
                Text(
                    text = "DISMISS",
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            }
        }
    ) {
        Text(
            text = "Task \"${task.description}\" completed",
            style = MaterialTheme.typography.bodyMedium,
            maxLines = 1
        )
    }
}

@Preview(showBackground = true)
@Composable
fun UndoSnackbarPreview() {
    MaterialTheme {
        UndoSnackbar(
            task = Task(
                id = "1",
                description = "Sample completed task"
            ),
            onUndo = {},
            onDismiss = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
fun UndoSnackbarLongTextPreview() {
    MaterialTheme {
        UndoSnackbar(
            task = Task(
                id = "1",
                description = "This is a very long task description that should be truncated in the snackbar"
            ),
            onUndo = {},
            onDismiss = {}
        )
    }
}