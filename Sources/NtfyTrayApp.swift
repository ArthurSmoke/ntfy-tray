import SwiftUI
import Cocoa

@main
struct NtfyTrayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
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
        
        // 监听系统休眠/唤醒
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        
        NotificationManager.shared.requestAuthorization { [weak self] granted in
            self?.logger.log("Authorization completed, granted: \(granted)")
            
            DispatchQueue.main.async {
                NSApp.setActivationPolicy(.accessory)
                self?.statusBarController = StatusBarController()
                self?.showStartupNotification()
            }
        }
    }
    
    @objc private func systemWillSleep(_ notification: Notification) {
        logger.log("System going to sleep, disconnecting WebSocket...")
        NtfyClient.shared.disconnect()
    }
    
    @objc private func systemDidWake(_ notification: Notification) {
        logger.log("System woke up, will reconnect in 3s...")
        // 等待网络稳定后重连
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            NtfyClient.shared.connect()
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
