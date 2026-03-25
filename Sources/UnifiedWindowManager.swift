import SwiftUI
import AppKit

class UnifiedWindowManager {
    static let shared = UnifiedWindowManager()
    
    private var window: NSWindow?
    
    private init() {}
    
    func show() {
        if window == nil {
            let contentView = UnifiedView()
                .environmentObject(SettingsManager.shared)
                .environmentObject(NtfyClient.shared)
            
            let hostingController = NSHostingController(rootView: contentView)
            
            window = NSWindow(contentViewController: hostingController)
            window?.title = "Ntfy Tray"
            window?.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            window?.titlebarAppearsTransparent = true
            window?.titleVisibility = .hidden
            window?.isReleasedWhenClosed = false
            window?.setContentSize(NSSize(width: 1020, height: 720))
            window?.minSize = NSSize(width: 600, height: 400)
            window?.center()
            window?.delegate = WindowDelegate.shared
            window?.backgroundColor = NSColor.windowBackgroundColor
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.close()
    }
    
    var isShown: Bool {
        window?.isVisible ?? false
    }
    
    func toggle() {
        if isShown {
            close()
        } else {
            show()
        }
    }
}

private class WindowDelegate: NSObject, NSWindowDelegate {
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
