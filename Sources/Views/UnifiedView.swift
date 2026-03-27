import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case notifications = "Notifications"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .notifications: return "bell.badge"
        case .settings: return "gear"
        }
    }
}

struct UnifiedView: View {
    @EnvironmentObject var ntfyClient: NtfyClient
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State private var selectedItem: SidebarItem = .notifications
    @State private var hoveredItem: SidebarItem?
    
    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 200)
            
            Divider()
                .opacity(0.5)
            
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var sidebar: some View {
        VStack(spacing: 0) {
            header
                .padding(.bottom, 8)
            
            VStack(spacing: 2) {
                ForEach(SidebarItem.allCases) { item in
                    sidebarButton(item)
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            footer
        }
        .background(
            Color(NSColor.controlBackgroundColor)
                .opacity(0.3)
        )
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ntfy Tray")
                        .font(.system(size: 15, weight: .semibold))
                    
                    connectionBadge
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Divider()
                .padding(.horizontal, 12)
        }
    }
    
    private var connectionBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(ntfyClient.isConnected ? Color.green : Color.red)
                .frame(width: 7, height: 7)
            
            Text(ntfyClient.isConnected ? "Connected" : "Disconnected")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    private func sidebarButton(_ item: SidebarItem) -> some View {
        Button(action: { selectedItem = item }) {
            HStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                
                Text(item.rawValue)
                    .font(.system(size: 13, weight: selectedItem == item ? .medium : .regular))
                
                Spacer()
                
                if item == .notifications && ntfyClient.unreadCount > 0 {
                    Text("\(ntfyClient.unreadCount)")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundFill(for: item))
            )
            .foregroundColor(foregroundColor(for: item))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredItem = hovering ? item : nil
        }
    }
    
    private func backgroundFill(for item: SidebarItem) -> Color {
        if selectedItem == item {
            return Color.blue.opacity(0.15)
        } else if hoveredItem == item {
            return Color(NSColor.controlBackgroundColor).opacity(0.8)
        }
        return Color.clear
    }
    
    private func foregroundColor(for item: SidebarItem) -> Color {
        if selectedItem == item {
            return .blue
        }
        return .primary
    }
    
    private var footer: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.horizontal, 12)
            
            HStack(spacing: 12) {
                if settingsManager.isConfigured {
                    Button(action: toggleConnection) {
                        Image(systemName: ntfyClient.isConnected ? "stop.circle" : "play.circle")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .help(ntfyClient.isConnected ? "Disconnect" : "Connect")
                }
                
                Spacer()
                
                Button(action: { NSApp.terminate(nil) }) {
                    Image(systemName: "power")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Quit")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch selectedItem {
        case .notifications:
            NotificationsPanel()
        case .settings:
            SettingsPanel()
        }
    }
    
    private func toggleConnection() {
        if ntfyClient.isConnected {
            ntfyClient.disconnect()
        } else {
            ntfyClient.connect()
        }
    }
}

struct NotificationsPanel: View {
    @EnvironmentObject var ntfyClient: NtfyClient
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            
            if !settingsManager.isConfigured {
                notConfiguredView
            } else if ntfyClient.messages.isEmpty {
                if ntfyClient.isConnected {
                    emptyStateView
                } else {
                    disconnectedView
                }
            } else {
                messageList
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var panelHeader: some View {
        HStack {
            Text("Notifications")
                .font(.system(size: 20, weight: .semibold))
            
            if ntfyClient.unreadCount > 0 {
                Text("\(ntfyClient.unreadCount)")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            if !ntfyClient.messages.isEmpty {
                Button(action: markAllAsRead) {
                    Label("Read All", systemImage: "checkmark.circle")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(ntfyClient.messages) { message in
                    ModernMessageRow(message: message)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    private var emptyStateView: some View {
        emptyState(icon: "bell.badge.slash", title: "No notifications", subtitle: "Messages will appear here when they arrive")
    }
    
    private var notConfiguredView: some View {
        VStack(spacing: 16) {
            emptyState(icon: "gear.badge", title: "Not configured", subtitle: "Set up your server and topics in Settings")
            
            Button("Open Settings") {
                NotificationCenter.default.post(name: .switchToSettings, object: nil)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
    
    private var disconnectedView: some View {
        VStack(spacing: 16) {
            emptyState(icon: "wifi.slash", title: "Disconnected", subtitle: "Connect to start receiving notifications")
            
            Button("Connect") {
                ntfyClient.connect()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
    
    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func markAllAsRead() {
        ntfyClient.markAllAsRead()
    }
}

struct ModernMessageRow: View {
    let message: NtfyMessage
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var ntfyClient: NtfyClient
    @State private var isHovered = false
    
    private var priorityColor: Color {
        guard let priority = message.priority else { return .secondary }
        switch priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .blue
        default: return .secondary
        }
    }
    
    private var opacity: Double {
        message.isRead ? 0.5 : 1.0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.title ?? message.topic)
                        .font(.system(size: 14, weight: message.isRead ? .regular : .semibold))
                        .lineLimit(1)
                    
                    if settingsManager.topics.count > 1 {
                        Label(message.topic, systemImage: "tray.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(formatTimestamp(message.time))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            if let messageText = message.message {
                Text(messageText)
                    .font(.system(size: 13))
                    .lineSpacing(1.5)
            }
            
            if let tags = message.tags, !tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(tags.prefix(4), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                    
                    if tags.count > 4 {
                        Text("+\(tags.count - 4)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let priority = message.priority, priority >= 4 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                    Text(priority == 5 ? "Urgent" : "High Priority")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(priorityColor)
            }
            
            if let clickURL = message.click, let _ = URL(string: clickURL) {
                Label(clickURL, systemImage: "link")
                    .font(.system(size: 11))
                    .foregroundColor(.blue)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .opacity(opacity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color(NSColor.controlBackgroundColor) : Color(NSColor.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(message.isRead ? 0.08 : 0.15), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            ntfyClient.markAsRead(message)
            if let clickURL = message.click, let url = URL(string: clickURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func formatTimestamp(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

extension Notification.Name {
    static let switchToSettings = Notification.Name("switchToSettings")
}
