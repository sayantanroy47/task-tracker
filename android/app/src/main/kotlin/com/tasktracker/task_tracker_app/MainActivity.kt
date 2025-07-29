package com.tasktracker.task_tracker_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

/**
 * MainActivity for Task Tracker App
 * Handles Flutter embedding, intent processing, and chat integration
 */
class MainActivity: FlutterActivity() {
    private var intentHandlerPlugin: IntentHandlerPlugin? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize intent handler plugin
        intentHandlerPlugin = IntentHandlerPlugin(this)
        
        // Process any shared content from launch intent
        handleInitialIntent()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register generated plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Register our custom intent handler plugin
        intentHandlerPlugin?.let { plugin ->
            flutterEngine.plugins.add(plugin)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        // Handle new intents (like shared content from other apps)
        intentHandlerPlugin?.handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        
        // Ensure we handle any pending intents when the app becomes active
        intentHandlerPlugin?.handleIntent(intent)
    }

    private fun handleInitialIntent() {
        // Handle shared content if the app was launched via share intent
        intent?.let { launchIntent ->
            intentHandlerPlugin?.handleIntent(launchIntent)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        intentHandlerPlugin = null
    }
}