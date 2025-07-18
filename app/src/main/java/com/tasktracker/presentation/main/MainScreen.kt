package com.tasktracker.presentation.main

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.tasktracker.presentation.components.TaskInputComponent
import com.tasktracker.presentation.components.TaskListComponent
import com.tasktracker.presentation.components.UndoSnackbar
import com.tasktracker.presentation.theme.TaskTrackerTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    highlightedTaskId: String? = null,
    viewModel: MainViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(id = com.tasktracker.R.string.app_name),
                        style = MaterialTheme.typography.headlineMedium
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        },
        snackbarHost = {
            SnackbarHost(hostState = snackbarHostState) { snackbarData ->
                // Show custom undo snackbar if there's a recently completed task
                uiState.recentlyCompletedTask?.let { completedTask ->
                    if (uiState.showUndoOption) {
                        UndoSnackbar(
                            task = completedTask,
                            onUndo = viewModel::undoTaskCompletion,
                            onDismiss = viewModel::dismissUndo
                        )
                    }
                }
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Task input component
                TaskInputComponent(
                    onCreateTask = viewModel::createTask,
                    onCreateTaskWithReminder = viewModel::createTaskWithReminder,
                    inputError = uiState.inputError,
                    showTaskCreatedFeedback = uiState.showTaskCreatedFeedback,
                    onClearInputError = viewModel::clearInputError,
                    onClearTaskCreatedFeedback = viewModel::clearTaskCreatedFeedback,
                    speechRecognitionService = viewModel.speechRecognitionService,
                    onRequestMicrophonePermission = viewModel::requestMicrophonePermission
                )
                
                // Task list component
                TaskListComponent(
                    tasks = uiState.activeTasks,
                    isLoading = uiState.isLoading,
                    onTaskComplete = viewModel::completeTask
                )
            }
            
            // Show undo snackbar at the bottom
            if (uiState.showUndoOption && uiState.recentlyCompletedTask != null) {
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(16.dp)
                ) {
                    UndoSnackbar(
                        task = uiState.recentlyCompletedTask,
                        onUndo = viewModel::undoTaskCompletion,
                        onDismiss = viewModel::dismissUndo
                    )
                }
            }
        }
    }
    
    // Auto-dismiss undo option after 5 seconds
    LaunchedEffect(uiState.showUndoOption) {
        if (uiState.showUndoOption) {
            kotlinx.coroutines.delay(5000)
            viewModel.dismissUndo()
        }
    }
}

@Preview(showBackground = true)
@Composable
fun MainScreenPreview() {
    TaskTrackerTheme {
        MainScreen()
    }
}

@Preview(showBackground = true, uiMode = android.content.res.Configuration.UI_MODE_NIGHT_YES)
@Composable
fun MainScreenDarkPreview() {
    TaskTrackerTheme {
        MainScreen()
    }
}