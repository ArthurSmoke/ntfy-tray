import SwiftUI
import AppKit

class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    
    private var settingsWindow: NSWindow?
    
    private init() {}
    
    func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .environmentObject(SettingsManager.shared)
                .environmentObject(NtfyClient.shared)
            
            let hostingController = NSHostingController(rootView: settingsView)
            
            settingsWindow = NSWindow(contentViewController: hostingController)
            settingsWindow?.title = "Ntfy Tray Settings"
            settingsWindow?.styleMask = [.titled, .closable, .miniaturizable]
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.center()
            settingsWindow?.delegate = WindowDelegate.shared
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeSettings() {
        settingsWindow?.close()
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    static let shared = WindowDelegate()
    
    private override init() {
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            window.isReleasedWhenClosed = false
        }
    }
}
