package com.tasktracker.presentation.components

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.tasktracker.presentation.speech.SpeechRecognitionService
import com.tasktracker.presentation.speech.SpeechRecognitionState
import com.tasktracker.presentation.theme.TaskTrackerTheme
import kotlinx.coroutines.flow.MutableStateFlow
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever

@RunWith(AndroidJUnit4::class)
class TaskInputComponentVoiceTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    @Test
    fun taskInputComponent_displaysMicrophoneButton() {
        val mockSpeechService = mock<SpeechRecognitionService>()
        val stateFlow = MutableStateFlow(SpeechRecognitionState())
        whenever(mockSpeechService.state).thenReturn(stateFlow)

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    speechRecognitionService = mockSpeechService
                )
            }
        }

        composeTestRule.onNodeWithContentDescription("Start voice input").assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_microphoneButtonStartsListening() {
        val mockSpeechService = mock<SpeechRecognitionService>()
        val stateFlow = MutableStateFlow(SpeechRecognitionState())
        whenever(mockSpeechService.state).thenReturn(stateFlow)
        var permissionRequested = false

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    speechRecognitionService = mockSpeechService,
                    onRequestMicrophonePermission = { permissionRequested = true }
                )
            }
        }

        composeTestRule.onNodeWithContentDescription("Start voice input").performClick()

        verify(mockSpeechService).startListening()
        assert(permissionRequested) { "Microphone permission should be requested" }
    }

    @Test
    fun taskInputComponent_displaysListeningFeedback() {
        val mockSpeechService = mock<SpeechRecognitionService>()
        val stateFlow = MutableStateFlow(SpeechRecognitionState(isListening = true))
        whenever(mockSpeechService.state).thenReturn(stateFlow)

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    speechRecognitionService = mockSpeechService
                )
            }
        }

        composeTestRule.onNodeWithText("Listening... Speak your task").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Stop listening").assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_displaysErrorFeedback() {
        val mockSpeechService = mock<SpeechRecognitionService>()
        val stateFlow = MutableStateFlow(SpeechRecognitionState(error = "No speech input"))
        whenever(mockSpeechService.state).thenReturn(stateFlow)

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    speechRecognitionService = mockSpeechService
                )
            }
        }

        composeTestRule.onNodeWithText("No speech input").assertIsDisplayed()
        composeTestRule.onNodeWithContentDescription("Retry voice input").assertIsDisplayed()
    }

    @Test
    fun taskInputComponent_retryButtonClearsErrorAndStartsListening() {
        val mockSpeechService = mock<SpeechRecognitionService>()
        val stateFlow = MutableStateFlow(SpeechRecognitionState(error = "No speech input"))
        whenever(mockSpeechService.state).thenReturn(stateFlow)

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    speechRecognitionService = mockSpeechService
                )
            }
        }

        composeTestRule.onNodeWithContentDescription("Retry voice input").performClick()

        verify(mockSpeechService).clearError()
        verify(mockSpeechService).startListening()
    }

    @Test
    fun taskInputComponent_stopButtonStopsListening() {
        val mockSpeechService = mock<SpeechRecognitionService>()
        val stateFlow = MutableStateFlow(SpeechRecognitionState(isListening = true))
        whenever(mockSpeechService.state).thenReturn(stateFlow)

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    speechRecognitionService = mockSpeechService
                )
            }
        }

        composeTestRule.onNodeWithContentDescription("Stop listening").performClick()

        verify(mockSpeechService).stopListening()
    }

    @Test
    fun taskInputComponent_automaticallyCreatesTaskFromSpeechResult() {
        val mockSpeechService = mock<SpeechRecognitionService>()
        val stateFlow = MutableStateFlow(SpeechRecognitionState(recognizedText = "Buy groceries"))
        whenever(mockSpeechService.state).thenReturn(stateFlow)
        var createdTask: String? = null

        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    speechRecognitionService = mockSpeechService,
                    onCreateTask = { createdTask = it }
                )
            }
        }

        composeTestRule.waitForIdle()

        assert(createdTask == "Buy groceries") { 
            "Task should be automatically created from speech recognition result" 
        }
        verify(mockSpeechService).clearResults()
    }

    @Test
    fun taskInputComponent_doesNotDisplayMicrophoneButtonWithoutSpeechService() {
        composeTestRule.setContent {
            TaskTrackerTheme {
                TaskInputComponent(
                    speechRecognitionService = null
                )
            }
        }

        composeTestRule.onNodeWithContentDescription("Start voice input").assertDoesNotExist()
    }
}