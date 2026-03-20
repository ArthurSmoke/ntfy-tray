import SwiftUI

@main
struct NtfyTrayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var ntfyClient = NtfyClient.shared
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(settingsManager)
                .environmentObject(ntfyClient)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private let logger = Logger.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.log("App launching...")
        
        if let iconImage = NSImage(named: "AppIcon") {
            NSApp.applicationIconImage = iconImage
        }
        
        NotificationManager.shared.requestAuthorization { [weak self] granted in
            self?.logger.log("Authorization completed, granted: \(granted)")
            
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.accessory)
                self?.statusBarController = StatusBarController()
                self?.showStartupNotification()
            }
        }
    }
    
    private func showStartupNotification() {
        logger.log("Showing startup notification...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationManager.shared.showTestNotification(
                title: "Ntfy Tray",
                body: "Ntfy已启动"
            )
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logger.log("App terminating...")
        NtfyClient.shared.disconnect()
    }
}
