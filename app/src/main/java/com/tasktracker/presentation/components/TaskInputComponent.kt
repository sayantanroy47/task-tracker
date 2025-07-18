package com.tasktracker.presentation.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.tasktracker.presentation.speech.SpeechRecognitionService
import com.tasktracker.presentation.speech.SpeechRecognitionState
import kotlinx.coroutines.delay

@Composable
fun TaskInputComponent(
    onCreateTask: (String) -> Unit = {},
    onCreateTaskWithReminder: (String, Long?) -> Unit = { _, _ -> },
    inputError: String? = null,
    showTaskCreatedFeedback: Boolean = false,
    onClearInputError: () -> Unit = {},
    onClearTaskCreatedFeedback: () -> Unit = {},
    speechRecognitionService: SpeechRecognitionService? = null,
    onRequestMicrophonePermission: () -> Unit = {},
    modifier: Modifier = Modifier
) {
    var taskDescription by remember { mutableStateOf("") }
    var reminderTime by remember { mutableStateOf<Long?>(null) }
    var showReminderPicker by remember { mutableStateOf(false) }
    val focusRequester = remember { FocusRequester() }
    val keyboardController = LocalSoftwareKeyboardController.current
    
    // Observe speech recognition state
    val speechState by speechRecognitionService?.state?.collectAsState() ?: remember { 
        mutableStateOf(SpeechRecognitionState()) 
    }
    
    // Clear input field and show feedback when task is created
    LaunchedEffect(showTaskCreatedFeedback) {
        if (showTaskCreatedFeedback) {
            taskDescription = ""
            keyboardController?.hide()
            delay(2000) // Show feedback for 2 seconds
            onClearTaskCreatedFeedback()
        }
    }
    
    // Clear input error when user starts typing
    LaunchedEffect(taskDescription) {
        if (inputError != null && taskDescription.isNotBlank()) {
            onClearInputError()
        }
    }
    
    // Handle speech recognition results
    LaunchedEffect(speechState.recognizedText) {
        if (speechState.recognizedText.isNotBlank()) {
            taskDescription = speechState.recognizedText
            // Automatically create task after successful speech recognition
            onCreateTask(speechState.recognizedText)
            speechRecognitionService?.clearResults()
        }
    }
    
    // Update text field with partial speech results
    LaunchedEffect(speechState.partialText) {
        if (speechState.partialText.isNotBlank() && speechState.isListening) {
            taskDescription = speechState.partialText
        }
    }
    
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Card(
            modifier = Modifier.fillMaxWidth(),
            elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = taskDescription,
                    onValueChange = { taskDescription = it },
                    modifier = Modifier
                        .weight(1f)
                        .focusRequester(focusRequester),
                    placeholder = {
                        Text(
                            text = "Add new task...",
                            style = MaterialTheme.typography.bodyLarge
                        )
                    },
                    keyboardOptions = KeyboardOptions(
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = {
                            if (taskDescription.isNotBlank()) {
                                onCreateTask(taskDescription)
                            }
                        }
                    ),
                    singleLine = true,
                    isError = inputError != null,
                    supportingText = if (inputError != null) {
                        { Text(text = inputError, color = MaterialTheme.colorScheme.error) }
                    } else null
                )
                
                // Reminder time picker button
                IconButton(
                    onClick = { showReminderPicker = true }
                ) {
                    Icon(
                        imageVector = Icons.Default.Schedule,
                        contentDescription = "Set reminder",
                        tint = if (reminderTime != null) {
                            MaterialTheme.colorScheme.primary
                        } else {
                            MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        }
                    )
                }
                
                // Microphone button for voice input
                if (speechRecognitionService != null) {
                    IconButton(
                        onClick = {
                            if (speechState.isActive) {
                                speechRecognitionService.stopListening()
                            } else {
                                onRequestMicrophonePermission()
                                speechRecognitionService.startListening()
                            }
                        }
                    ) {
                        Icon(
                            imageVector = if (speechState.isActive) Icons.Default.MicOff else Icons.Default.Mic,
                            contentDescription = if (speechState.isActive) "Stop listening" else "Start voice input",
                            tint = when {
                                speechState.isActive -> MaterialTheme.colorScheme.error
                                speechState.error != null -> MaterialTheme.colorScheme.error
                                else -> MaterialTheme.colorScheme.primary
                            }
                        )
                    }
                }
                
                IconButton(
                    onClick = {
                        if (taskDescription.isNotBlank()) {
                            if (reminderTime != null) {
                                onCreateTaskWithReminder(taskDescription, reminderTime)
                            } else {
                                onCreateTask(taskDescription)
                            }
                        }
                    },
                    enabled = taskDescription.isNotBlank()
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                        contentDescription = "Create task",
                        tint = if (taskDescription.isNotBlank()) {
                            MaterialTheme.colorScheme.primary
                        } else {
                            MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f)
                        }
                    )
                }
            }
        }
        
        // Reminder time display
        reminderTime?.let { time ->
            ReminderTimeDisplay(
                reminderTime = time,
                onClearReminder = { reminderTime = null }
            )
        }
        
        // Speech recognition error feedback
        AnimatedVisibility(
            visible = speechState.error != null,
            enter = slideInVertically(initialOffsetY = { -it }) + fadeIn(),
            exit = slideOutVertically(targetOffsetY = { -it }) + fadeOut()
        ) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = speechState.error ?: "",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onErrorContainer,
                        modifier = Modifier.weight(1f)
                    )
                    if (speechState.error?.contains("No speech input") == true || 
                        speechState.error?.contains("timeout") == true) {
                        IconButton(
                            onClick = {
                                speechRecognitionService?.clearError()
                                speechRecognitionService?.startListening()
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Mic,
                                contentDescription = "Retry voice input",
                                tint = MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                    }
                }
            }
        }
        
        // Speech recognition listening feedback
        AnimatedVisibility(
            visible = speechState.isListening,
            enter = slideInVertically(initialOffsetY = { -it }) + fadeIn(),
            exit = slideOutVertically(targetOffsetY = { -it }) + fadeOut()
        ) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.secondaryContainer
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Mic,
                        contentDescription = "Listening",
                        tint = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                    Text(
                        text = "Listening... Speak your task",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                }
            }
        }
        
        // Success feedback animation
        AnimatedVisibility(
            visible = showTaskCreatedFeedback,
            enter = slideInVertically(initialOffsetY = { -it }) + fadeIn(),
            exit = slideOutVertically(targetOffsetY = { -it }) + fadeOut()
        ) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = "Task created",
                        tint = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                    Text(
                        text = "Task created successfully!",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }
        }
    }
    
    // Reminder time picker dialog
    if (showReminderPicker) {
        ReminderTimePicker(
            onTimeSelected = { selectedTime ->
                reminderTime = selectedTime
                showReminderPicker = false
            },
            onDismiss = { showReminderPicker = false }
        )
    }
}

@Preview(showBackground = true)
@Composable
fun TaskInputComponentPreview() {
    MaterialTheme {
        TaskInputComponent()
    }
}

@Preview(showBackground = true)
@Composable
fun TaskInputComponentWithErrorPreview() {
    MaterialTheme {
        TaskInputComponent(
            inputError = "Task description cannot be empty"
        )
    }
}

@Preview(showBackground = true)
@Composable
fun TaskInputComponentWithFeedbackPreview() {
    MaterialTheme {
        TaskInputComponent(
            showTaskCreatedFeedback = true
        )
    }
}