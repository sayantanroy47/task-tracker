package com.tasktracker.presentation.speech

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SpeechPermissionHandler @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val _permissionState = MutableStateFlow(PermissionState.UNKNOWN)
    val permissionState: StateFlow<PermissionState> = _permissionState.asStateFlow()
    
    private var permissionLauncher: ActivityResultLauncher<String>? = null
    
    fun initialize(activity: ComponentActivity) {
        permissionLauncher = activity.registerForActivityResult(
            ActivityResultContracts.RequestPermission()
        ) { isGranted ->
            _permissionState.value = if (isGranted) {
                PermissionState.GRANTED
            } else {
                PermissionState.DENIED
            }
        }
        
        // Check initial permission state
        checkPermission()
    }
    
    fun checkPermission(): Boolean {
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
        
        _permissionState.value = if (hasPermission) {
            PermissionState.GRANTED
        } else {
            PermissionState.DENIED
        }
        
        return hasPermission
    }
    
    fun requestPermission() {
        if (checkPermission()) {
            return // Already granted
        }
        
        _permissionState.value = PermissionState.REQUESTING
        permissionLauncher?.launch(Manifest.permission.RECORD_AUDIO)
    }
    
    fun hasPermission(): Boolean {
        return _permissionState.value == PermissionState.GRANTED
    }
    
    fun shouldShowRationale(activity: ComponentActivity): Boolean {
        return activity.shouldShowRequestPermissionRationale(Manifest.permission.RECORD_AUDIO)
    }
}

enum class PermissionState {
    UNKNOWN,
    GRANTED,
    DENIED,
    REQUESTING
}