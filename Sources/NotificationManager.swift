import Foundation
import AppKit
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    @Published var hasPermission = false
    @Published var permissionRequested = false
    
    private let logger = Logger.shared
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
        logger.log("NotificationManager initialized")
    }
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasPermission = settings.authorizationStatus == .authorized
                self?.logger.log("Notification permission status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        logger.log("Requesting notification authorization...")
        
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                self?.permissionRequested = true
                
                if let error = error {
                    self?.logger.log("Notification authorization error: \(error)")
                } else {
                    self?.logger.log("Notification authorization granted: \(granted)")
                }
                
                completion?(granted)
            }
        }
    }
    
    func showNotification(for message: NtfyMessage) {
        logger.log("Showing notification for message: \(message.id)")
        
        let content = UNMutableNotificationContent()
        
        content.title = message.title ?? message.topic
        content.body = message.message ?? "New notification"
        content.threadIdentifier = message.topic
        
        if SettingsManager.shared.soundEnabled {
            content.sound = .default
        }
        
        if let priority = message.priority {
            switch priority {
            case 5:
                content.interruptionLevel = .timeSensitive
                content.relevanceScore = 1.0
            case 4:
                content.interruptionLevel = .active
                content.relevanceScore = 0.8
            case 3:
                content.interruptionLevel = .active
                content.relevanceScore = 0.5
            case 1...2:
                content.interruptionLevel = .passive
                content.relevanceScore = 0.2
            default:
                content.interruptionLevel = .active
                content.relevanceScore = 0.5
            }
        } else {
            content.interruptionLevel = .active
            content.relevanceScore = 0.5
        }
        
        if let clickURL = message.click, URL(string: clickURL) != nil {
            content.userInfo["clickURL"] = clickURL
        }
        
        content.userInfo["messageId"] = message.id
        content.userInfo["topic"] = message.topic
        
        if let tags = message.tags, !tags.isEmpty {
            content.subtitle = tags.joined(separator: ", ")
        }
        
        let request = UNNotificationRequest(
            identifier: message.id,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.log("Failed to show notification: \(error)")
            } else {
                self?.logger.log("Notification shown successfully: \(message.id)")
            }
        }
    }
    
    func showTestNotification(title: String, body: String) {
        logger.log("Showing test notification: \(title) - \(body)")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .active
        
        let request = UNNotificationRequest(
            identifier: "test-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                self?.logger.log("Failed to show test notification: \(error)")
            } else {
                self?.logger.log("Test notification added successfully")
            }
        }
    }
    
    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func clearNotification(withIdentifier identifier: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    func openSystemNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.log("Notification will present: \(notification.request.identifier)")
        completionHandler([.banner, .sound, .list])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let clickURLString = userInfo["clickURL"] as? String,
           let url = URL(string: clickURLString) {
            NSWorkspace.shared.open(url)
        }
        
        completionHandler()
    }
}
