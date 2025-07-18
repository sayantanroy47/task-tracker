package com.tasktracker.presentation.speech

import android.content.Context
import android.speech.SpeechRecognizer
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.whenever
import com.google.common.truth.Truth.assertThat

@OptIn(ExperimentalCoroutinesApi::class)
class SpeechRecognitionServiceTest {

    @Mock
    private lateinit var context: Context

    private lateinit var speechRecognitionService: SpeechRecognitionService

    @Before
    fun setup() {
        MockitoAnnotations.openMocks(this)
        speechRecognitionService = SpeechRecognitionService(context)
    }

    @Test
    fun `initial state is correct`() = runTest {
        // Given - initial state
        val state = speechRecognitionService.state.value
        
        // Then
        assertThat(state.isListening).isFalse()
        assertThat(state.isProcessing).isFalse()
        assertThat(state.recognizedText).isEmpty()
        assertThat(state.partialText).isEmpty()
        assertThat(state.error).isNull()
        assertThat(state.audioLevel).isEqualTo(0f)
        assertThat(state.isActive).isFalse()
    }

    @Test
    fun `clearResults clears text and error`() = runTest {
        // Given - service with some state
        // We can't easily mock the internal state changes, so we test the clear method directly
        
        // When
        speechRecognitionService.clearResults()
        
        // Then
        val state = speechRecognitionService.state.value
        assertThat(state.recognizedText).isEmpty()
        assertThat(state.partialText).isEmpty()
        assertThat(state.error).isNull()
    }

    @Test
    fun `clearError clears error state`() = runTest {
        // When
        speechRecognitionService.clearError()
        
        // Then
        val state = speechRecognitionService.state.value
        assertThat(state.error).isNull()
    }

    @Test
    fun `stopListening updates state correctly`() = runTest {
        // When
        speechRecognitionService.stopListening()
        
        // Then
        val state = speechRecognitionService.state.value
        assertThat(state.isListening).isFalse()
        assertThat(state.isProcessing).isFalse()
        assertThat(state.audioLevel).isEqualTo(0f)
    }

    @Test
    fun `destroy resets state`() = runTest {
        // When
        speechRecognitionService.destroy()
        
        // Then
        val state = speechRecognitionService.state.value
        assertThat(state.isListening).isFalse()
        assertThat(state.isProcessing).isFalse()
        assertThat(state.recognizedText).isEmpty()
        assertThat(state.partialText).isEmpty()
        assertThat(state.error).isNull()
        assertThat(state.audioLevel).isEqualTo(0f)
    }

    @Test
    fun `SpeechRecognitionState isActive returns true when listening`() {
        // Given
        val state = SpeechRecognitionState(isListening = true)
        
        // Then
        assertThat(state.isActive).isTrue()
    }

    @Test
    fun `SpeechRecognitionState isActive returns true when processing`() {
        // Given
        val state = SpeechRecognitionState(isProcessing = true)
        
        // Then
        assertThat(state.isActive).isTrue()
    }

    @Test
    fun `SpeechRecognitionState isActive returns false when neither listening nor processing`() {
        // Given
        val state = SpeechRecognitionState(isListening = false, isProcessing = false)
        
        // Then
        assertThat(state.isActive).isFalse()
    }
}