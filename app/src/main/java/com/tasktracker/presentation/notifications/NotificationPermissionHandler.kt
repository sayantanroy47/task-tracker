package com.tasktracker.presentation.notifications

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
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
class NotificationPermissionHandler @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val _permissionState = MutableStateFlow(NotificationPermissionState.UNKNOWN)
    val permissionState: StateFlow<NotificationPermissionState> = _permissionState.asStateFlow()
    
    private var permissionLauncher: ActivityResultLauncher<String>? = null
    
    fun initialize(activity: ComponentActivity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissionLauncher = activity.registerForActivityResult(
                ActivityResultContracts.RequestPermission()
            ) { isGranted ->
                _permissionState.value = if (isGranted) {
                    NotificationPermissionState.GRANTED
                } else {
                    NotificationPermissionState.DENIED
                }
            }
        }
        
        // Check initial permission state
        checkPermission()
    }
    
    fun checkPermission(): Boolean {
        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            // For Android 12 and below, notifications are enabled by default
            true
        }
        
        _permissionState.value = if (hasPermission) {
            NotificationPermissionState.GRANTED
        } else {
            NotificationPermissionState.DENIED
        }
        
        return hasPermission
    }
    
    fun requestPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            // No need to request permission on older Android versions
            _permissionState.value = NotificationPermissionState.GRANTED
            return
        }
        
        if (checkPermission()) {
            return // Already granted
        }
        
        _permissionState.value = NotificationPermissionState.REQUESTING
        permissionLauncher?.launch(Manifest.permission.POST_NOTIFICATIONS)
    }
    
    fun hasPermission(): Boolean {
        return _permissionState.value == NotificationPermissionState.GRANTED
    }
    
    fun shouldShowRationale(activity: ComponentActivity): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.shouldShowRequestPermissionRationale(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            false
        }
    }
}

enum class NotificationPermissionState {
    UNKNOWN,
    GRANTED,
    DENIED,
    REQUESTING
}