import SwiftUI
import Combine

class StatusBarController: ObservableObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var cancellables = Set<AnyCancellable>()
    
    private let settingsManager = SettingsManager.shared
    private let ntfyClient = NtfyClient.shared
    
    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()
        
        setupMenuBar()
        setupPopover()
        observeConnectionStatus()
        observeSettingsChanges()
        
        if settingsManager.isConfigured {
            ntfyClient.connect()
        }
    }
    
    private func setupMenuBar() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bell", accessibilityDescription: "Ntfy Tray")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: NotificationListView()
                .environmentObject(settingsManager)
                .environmentObject(ntfyClient)
        )
    }
    
    private func observeConnectionStatus() {
        ntfyClient.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.updateMenuIcon(connected: isConnected)
            }
            .store(in: &cancellables)
        
        ntfyClient.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateBadgeCount()
            }
            .store(in: &cancellables)
    }
    
    private func observeSettingsChanges() {
        settingsManager.$serverURL
            .combineLatest(settingsManager.$topics)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _ in
                if self?.settingsManager.isConfigured == true {
                    self?.ntfyClient.connect()
                } else {
                    self?.ntfyClient.disconnect()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateMenuIcon(connected: Bool) {
        if let button = statusItem.button {
            let imageName = connected ? "bell.fill" : "bell.slash"
            button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "Ntfy Tray")
            button.image?.isTemplate = true
        }
    }
    
    private func updateBadgeCount() {
        guard settingsManager.showBadgeCount else {
            statusItem.length = NSStatusItem.squareLength
            statusItem.button?.title = ""
            return
        }
        
        let unreadCount = ntfyClient.messages.count
        if unreadCount > 0 {
            statusItem.length = NSStatusItem.variableLength
            statusItem.button?.title = " \(unreadCount)"
        } else {
            statusItem.length = NSStatusItem.squareLength
            statusItem.button?.title = ""
        }
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else if let button = statusItem.button {
            ntfyClient.messages.removeAll()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
}
