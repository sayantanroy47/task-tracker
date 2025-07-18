package com.tasktracker.presentation.speech

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SpeechRecognitionService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private var speechRecognizer: SpeechRecognizer? = null
    
    private val _state = MutableStateFlow(SpeechRecognitionState())
    val state: StateFlow<SpeechRecognitionState> = _state.asStateFlow()
    
    private val recognitionListener = object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {
            _state.value = _state.value.copy(
                isListening = true,
                error = null
            )
        }
        
        override fun onBeginningOfSpeech() {
            _state.value = _state.value.copy(
                isProcessing = true
            )
        }
        
        override fun onRmsChanged(rmsdB: Float) {
            _state.value = _state.value.copy(
                audioLevel = rmsdB
            )
        }
        
        override fun onBufferReceived(buffer: ByteArray?) {
            // Not used in this implementation
        }
        
        override fun onEndOfSpeech() {
            _state.value = _state.value.copy(
                isListening = false,
                isProcessing = true
            )
        }
        
        override fun onError(error: Int) {
            val errorMessage = when (error) {
                SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
                SpeechRecognizer.ERROR_CLIENT -> "Client side error"
                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
                SpeechRecognizer.ERROR_NETWORK -> "Network error"
                SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                SpeechRecognizer.ERROR_NO_MATCH -> "No speech input"
                SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
                SpeechRecognizer.ERROR_SERVER -> "Server error"
                SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
                else -> "Unknown error"
            }
            
            _state.value = _state.value.copy(
                isListening = false,
                isProcessing = false,
                error = errorMessage,
                audioLevel = 0f
            )
        }
        
        override fun onResults(results: Bundle?) {
            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            val recognizedText = matches?.firstOrNull() ?: ""
            
            _state.value = _state.value.copy(
                isListening = false,
                isProcessing = false,
                recognizedText = recognizedText,
                error = null,
                audioLevel = 0f
            )
        }
        
        override fun onPartialResults(partialResults: Bundle?) {
            val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
            val partialText = matches?.firstOrNull() ?: ""
            
            _state.value = _state.value.copy(
                partialText = partialText
            )
        }
        
        override fun onEvent(eventType: Int, params: Bundle?) {
            // Not used in this implementation
        }
    }
    
    fun startListening() {
        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            _state.value = _state.value.copy(
                error = "Speech recognition not available"
            )
            return
        }
        
        // Reset state
        _state.value = SpeechRecognitionState()
        
        // Create speech recognizer if needed
        if (speechRecognizer == null) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
            speechRecognizer?.setRecognitionListener(recognitionListener)
        }
        
        // Create recognition intent
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak your task...")
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        }
        
        // Start listening
        speechRecognizer?.startListening(intent)
    }
    
    fun stopListening() {
        speechRecognizer?.stopListening()
        _state.value = _state.value.copy(
            isListening = false,
            isProcessing = false,
            audioLevel = 0f
        )
    }
    
    fun clearResults() {
        _state.value = _state.value.copy(
            recognizedText = "",
            partialText = "",
            error = null
        )
    }
    
    fun clearError() {
        _state.value = _state.value.copy(error = null)
    }
    
    fun destroy() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        _state.value = SpeechRecognitionState()
    }
}

data class SpeechRecognitionState(
    val isListening: Boolean = false,
    val isProcessing: Boolean = false,
    val recognizedText: String = "",
    val partialText: String = "",
    val error: String? = null,
    val audioLevel: Float = 0f
) {
    val isActive: Boolean get() = isListening || isProcessing
}