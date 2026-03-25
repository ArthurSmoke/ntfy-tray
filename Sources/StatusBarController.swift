import SwiftUI
import Combine

class StatusBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem
    private var cancellables = Set<AnyCancellable>()
    
    private let settingsManager = SettingsManager.shared
    private let ntfyClient = NtfyClient.shared
    private let unifiedWindowManager = UnifiedWindowManager.shared
    
    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        super.init()
        
        setupMenuBar()
        observeConnectionStatus()
        observeSettingsChanges()
        
        if settingsManager.isConfigured {
            ntfyClient.connect()
        }
    }
    
    private func setupMenuBar() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bell", accessibilityDescription: "Ntfy Tray")
            button.action = #selector(toggleWindow(_:))
            button.target = self
        }
    }
    
    private func observeConnectionStatus() {
        ntfyClient.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.updateMenuIcon(connected: isConnected)
            }
            .store(in: &cancellables)
        
        ntfyClient.$unreadCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.updateBadgeCount(count: count)
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
    
    private func updateBadgeCount(count: Int) {
        guard settingsManager.showBadgeCount else {
            statusItem.length = NSStatusItem.variableLength
            statusItem.button?.image = NSImage(systemSymbolName: "bell", accessibilityDescription: "Ntfy Tray")
            statusItem.button?.attributedTitle = NSAttributedString()
            return
        }
        
        if count > 0 {
            statusItem.length = NSStatusItem.variableLength
            statusItem.button?.image = nil
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: NSColor.white,
                .backgroundColor: NSColor.black
            ]
            let attributedString = NSAttributedString(string: " \(count) ", attributes: attributes)
            statusItem.button?.attributedTitle = attributedString
        } else {
            statusItem.length = NSStatusItem.variableLength
            statusItem.button?.image = NSImage(systemSymbolName: "bell", accessibilityDescription: "Ntfy Tray")
            statusItem.button?.attributedTitle = NSAttributedString()
        }
    }
    
    @objc private func toggleWindow(_ sender: AnyObject?) {
        unifiedWindowManager.toggle()
    }
}
