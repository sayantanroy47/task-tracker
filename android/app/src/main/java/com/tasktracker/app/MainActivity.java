package com.tasktracker.app;

import android.content.Intent;
import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import androidx.annotation.NonNull;

public class MainActivity extends FlutterActivity {
    private IntentHandlerPlugin intentHandlerPlugin;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        // Initialize and register the intent handler plugin
        intentHandlerPlugin = new IntentHandlerPlugin(this);
        flutterEngine.getPlugins().add(intentHandlerPlugin);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        
        // Handle the new intent through our plugin
        if (intentHandlerPlugin != null) {
            intentHandlerPlugin.handleIntent(intent);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        
        // Handle intent when app is opened/resumed
        if (intentHandlerPlugin != null) {
            intentHandlerPlugin.handleIntent(getIntent());
        }
    }
}