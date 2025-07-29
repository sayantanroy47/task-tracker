import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var intentHandlerChannel: FlutterMethodChannel?
    private var pendingSharedContent: [String: Any]?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // Setup intent handler method channel
        intentHandlerChannel = FlutterMethodChannel(
            name: "task_tracker/intent_handler",
            binaryMessenger: controller.binaryMessenger
        )
        
        intentHandlerChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            self?.handleMethodCall(call: call, result: result)
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            result(nil)
        case "getPendingSharedContent":
            if let content = pendingSharedContent {
                result(content)
                pendingSharedContent = nil // Clear after retrieving
            } else {
                result(nil)
            }
        case "clearPendingContent":
            pendingSharedContent = nil
            result(nil)
        case "isAvailable":
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Handle URL schemes (deep linking)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        if url.scheme == "tasktracker" {
            // Handle deep link URL
            handleDeepLink(url: url)
            return true
        }
        return super.application(app, open: url, options: options)
    }
    
    // Handle shared content from other apps
    override func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL {
                handleDeepLink(url: url)
                return true
            }
        }
        
        // Handle shared text content
        if let textContent = userActivity.userInfo?["NSExtensionJavaScriptPreprocessingResultsKey"] as? [String: Any],
           let results = textContent["results"] as? [String: Any],
           let text = results["text"] as? String {
            handleSharedText(text: text, from: nil)
            return true
        }
        
        return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }
    
    private func handleDeepLink(url: URL) {
        // Extract shared text from URL parameters if any
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let queryItems = components?.queryItems {
            for item in queryItems {
                if item.name == "text", let text = item.value {
                    handleSharedText(text: text, from: "Deep Link")
                    break
                }
            }
        }
    }
    
    private func handleSharedText(text: String, from appName: String?) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let sharedContent: [String: Any] = [
            "text": trimmedText,
            "appName": appName as Any,
            "senderInfo": nil as Any,
            "conversationContext": nil as Any
        ]
        
        // If Flutter is ready, send immediately, otherwise store for later
        if let channel = intentHandlerChannel {
            channel.invokeMethod("onSharedContent", arguments: sharedContent)
        } else {
            pendingSharedContent = sharedContent
        }
    }
}

// MARK: - Share Extension Support
extension AppDelegate {
    
    // This method is called when the app is opened via share extension
    override func application(
        _ application: UIApplication,
        handleOpen url: URL
    ) -> Bool {
        if url.scheme == "tasktracker" {
            handleDeepLink(url: url)
            return true
        }
        return false
    }
}