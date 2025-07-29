package com.tasktracker.task_tracker_app;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import java.util.HashMap;
import java.util.Map;

/**
 * Plugin for handling shared content intents from external apps
 */
public class IntentHandlerPlugin implements FlutterPlugin, MethodCallHandler {
    private static final String CHANNEL = "task_tracker/intent_handler";
    private MethodChannel channel;
    private MainActivity mainActivity;
    private Map<String, Object> pendingSharedContent;

    public IntentHandlerPlugin(MainActivity activity) {
        this.mainActivity = activity;
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "initialize":
                initialize(result);
                break;
            case "getPendingSharedContent":
                getPendingSharedContent(result);
                break;
            case "clearPendingContent":
                clearPendingContent(result);
                break;
            case "isAvailable":
                result.success(true);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    private void initialize(Result result) {
        try {
            // Check if there's an intent waiting to be processed
            if (mainActivity != null) {
                Intent intent = mainActivity.getIntent();
                handleIntent(intent);
            }
            result.success(null);
        } catch (Exception e) {
            result.error("INIT_ERROR", "Failed to initialize intent handler", e.getMessage());
        }
    }

    private void getPendingSharedContent(Result result) {
        if (pendingSharedContent != null) {
            result.success(pendingSharedContent);
            pendingSharedContent = null; // Clear after retrieving
        } else {
            result.success(null);
        }
    }

    private void clearPendingContent(Result result) {
        pendingSharedContent = null;
        result.success(null);
    }

    /**
     * Handle an incoming intent, typically called from MainActivity
     */
    public void handleIntent(Intent intent) {
        if (intent == null) return;

        String action = intent.getAction();
        String type = intent.getType();

        if (Intent.ACTION_SEND.equals(action) && "text/plain".equals(type)) {
            handleSharedText(intent);
        }
    }

    private void handleSharedText(Intent intent) {
        String sharedText = intent.getStringExtra(Intent.EXTRA_TEXT);
        if (sharedText == null || sharedText.trim().isEmpty()) {
            return;
        }

        // Extract additional metadata
        String appName = getAppName(intent);
        String subject = intent.getStringExtra(Intent.EXTRA_SUBJECT);

        Map<String, Object> sharedContent = new HashMap<>();
        sharedContent.put("text", sharedText.trim());
        sharedContent.put("appName", appName);
        sharedContent.put("senderInfo", subject);
        sharedContent.put("conversationContext", null);

        // If Flutter is ready, send immediately, otherwise store for later
        if (channel != null) {
            channel.invokeMethod("onSharedContent", sharedContent);
        } else {
            pendingSharedContent = sharedContent;
        }
    }

    private String getAppName(Intent intent) {
        try {
            if (mainActivity == null) return null;
            
            PackageManager pm = mainActivity.getPackageManager();
            String packageName = intent.getStringExtra("android.intent.extra.PACKAGE_NAME");
            
            if (packageName == null) {
                // Try to get the calling package
                packageName = mainActivity.getCallingPackage();
            }
            
            if (packageName == null) {
                // Try to resolve from the intent
                ResolveInfo resolveInfo = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
                if (resolveInfo != null && resolveInfo.activityInfo != null) {
                    packageName = resolveInfo.activityInfo.packageName;
                }
            }

            if (packageName != null) {
                CharSequence appName = pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0));
                return appName != null ? appName.toString() : null;
            }
        } catch (Exception e) {
            // Ignore errors in getting app name
        }
        
        return null;
    }

    /**
     * Set the main activity reference
     */
    public void setMainActivity(MainActivity activity) {
        this.mainActivity = activity;
    }
}