package com.tasktracker

import android.app.Application
import com.tasktracker.util.MemoryLeakDetector
import com.tasktracker.util.PerformanceMonitor
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class TaskTrackerApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        
        // Initialize performance monitoring
        PerformanceMonitor.logMemoryUsage("Application onCreate")
        
        // Initialize memory leak detection (only in debug builds)
        if (BuildConfig.DEBUG) {
            MemoryLeakDetector.getInstance().initialize(this)
        }
    }
    
    override fun onLowMemory() {
        super.onLowMemory()
        PerformanceMonitor.logMemoryUsage("Low memory warning")
        
        // Force garbage collection on low memory
        System.gc()
    }
    
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        PerformanceMonitor.logMemoryUsage("Memory trim level: $level")
        
        when (level) {
            TRIM_MEMORY_RUNNING_CRITICAL,
            TRIM_MEMORY_COMPLETE -> {
                // Aggressive cleanup
                System.gc()
            }
        }
    }
}