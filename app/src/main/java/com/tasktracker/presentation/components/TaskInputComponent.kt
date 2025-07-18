package com.tasktracker.presentation.components

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.Repeat
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
import androidx.compose.ui.draw.scale
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.tasktracker.domain.model.RecurrenceType
import com.tasktracker.presentation.components.glassmorphism.GlassCard
import com.tasktracker.presentation.components.glassmorphism.GlassTextField
import com.tasktracker.presentation.components.glassmorphism.GlassButton
import com.tasktracker.presentation.speech.SpeechRecognitionService
import com.tasktracker.presentation.speech.SpeechRecognitionState
import com.tasktracker.presentation.theme.adaptiveGlassColors
import kotlinx.coroutines.delay

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun TaskInputComponent(
    onCreateTask: (String) -> Unit = {},
    onCreateTaskWithReminder: (String, Long?) -> Unit = { _, _ -> },
    onCreateTaskWithRecurrence: (String, Long?, RecurrenceType?) -> Unit = { _, _, _ -> },
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
    var recurrenceType by remember { mutableStateOf<RecurrenceType?>(null) }
    var showReminderPicker by remember { mutableStateOf(false) }
    var showRecurrencePicker by remember { mutableStateOf(false) }
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
    
    val glassColors = adaptiveGlassColors()
    val hapticFeedback = LocalHapticFeedback.current
    
    // Animation for button press feedback
    val buttonScale by animateFloatAsState(
        targetValue = if (taskDescription.isNotBlank()) 1f else 0.95f,
        animationSpec = tween(durationMillis = 150),
        label = "button_scale"
    )
    
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        GlassCard(
            modifier = Modifier.fillMaxWidth(),
            contentPadding = PaddingValues(16.dp),
            transparency = 0.15f,
            elevation = 6.dp
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                GlassTextField(
                    value = taskDescription,
                    onValueChange = { taskDescription = it },
                    modifier = Modifier
                        .weight(1f)
                        .focusRequester(focusRequester),
                    placeholder = "Add new task...",
                    keyboardOptions = KeyboardOptions(
                        imeAction = ImeAction.Done
                    ),
                    keyboardActions = KeyboardActions(
                        onDone = {
                            if (taskDescription.isNotBlank()) {
                                hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
                                onCreateTask(taskDescription)
                            }
                        }
                    )
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
                
                // Recurrence picker button
                IconButton(
                    onClick = { showRecurrencePicker = true }
                ) {
                    Icon(
                        imageVector = Icons.Default.Repeat,
                        contentDescription = "Set recurrence",
                        tint = if (recurrenceType != null) {
                            MaterialTheme.colorScheme.secondary
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
                            if (reminderTime != null || recurrenceType != null) {
                                onCreateTaskWithRecurrence(taskDescription, reminderTime, recurrenceType)
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
        
        // Recurrence display
        recurrenceType?.let { type ->
            RecurrenceDisplay(
                recurrenceType = type,
                onClearRecurrence = { recurrenceType = null }
            )
        }
        
        // Speech recognition error feedback
        AnimatedVisibility(
            visible = speechState.error != null,
            enter = slideInVertically(initialOffsetY = { -it }) + fadeIn(),
            exit = slideOutVertically(targetOffsetY = { -it }) + fadeOut()
        ) {
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(12.dp),
                transparency = 0.2f,
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = speechState.error ?: "",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.weight(1f)
                    )
                    if (speechState.error?.contains("No speech input") == true || 
                        speechState.error?.contains("timeout") == true) {
                        IconButton(
                            onClick = {
                                hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
                                speechRecognitionService?.clearError()
                                speechRecognitionService?.startListening()
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Mic,
                                contentDescription = "Retry voice input",
                                tint = MaterialTheme.colorScheme.error
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
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(12.dp),
                transparency = 0.18f,
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Mic,
                        contentDescription = "Listening",
                        tint = MaterialTheme.colorScheme.secondary,
                        modifier = Modifier.size(20.dp)
                    )
                    Text(
                        text = "Listening... Speak your task",
                        style = MaterialTheme.typography.bodyMedium,
                        color = glassColors.onSurface
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
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(12.dp),
                transparency = 0.18f,
                shape = RoundedCornerShape(12.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = "Task created",
                        tint = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(20.dp)
                    )
                    Text(
                        text = "Task created successfully!",
                        style = MaterialTheme.typography.bodyMedium,
                        color = glassColors.onSurface
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
    
    // Recurrence picker dialog
    if (showRecurrencePicker) {
        RecurrencePicker(
            currentRecurrence = recurrenceType,
            onRecurrenceSelected = { selectedRecurrence ->
                recurrenceType = selectedRecurrence
                showRecurrencePicker = false
            },
            onDismiss = { showRecurrencePicker = false }
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