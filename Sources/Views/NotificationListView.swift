import SwiftUI

struct NotificationListView: View {
    @EnvironmentObject var ntfyClient: NtfyClient
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            if !settingsManager.isConfigured {
                notConfiguredView
            } else if ntfyClient.messages.isEmpty {
                if ntfyClient.isConnected {
                    emptyStateView
                } else {
                    disconnectedEmptyView
                }
            } else {
                messageListView
            }
            
            footerView
        }
        .frame(width: 320, height: 400)
    }
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                connectionIndicator
                Text(connectionStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { clearAllMessages() }) {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Clear all messages")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var connectionIndicator: some View {
        Circle()
            .fill(ntfyClient.isConnected ? Color.green : Color.red)
            .frame(width: 8, height: 8)
    }
    
    private var connectionStatusText: String {
        if settingsManager.isConfigured {
            let topicsCount = settingsManager.topics.count
            if ntfyClient.isConnected {
                return topicsCount == 1 
                    ? "Connected to \(settingsManager.topics[0])"
                    : "Connected to \(topicsCount) topics"
            }
            return "Disconnected"
        }
        return "Not configured"
    }
    
    private var messageListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(ntfyClient.messages) { message in
                    MessageRow(message: message)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No notifications yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Notifications from your topics will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var notConfiguredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gear")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Not configured")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Please configure your server and topic in settings")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Open Settings") {
                SettingsWindowManager.shared.showSettings()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var disconnectedEmptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Disconnected")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Click Connect to start receiving notifications")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Connect") {
                ntfyClient.connect()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var footerView: some View {
        HStack {
            Button(action: { SettingsWindowManager.shared.showSettings() }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
            .help("Settings")
            
            Spacer()
            
            if settingsManager.isConfigured {
                Button(action: { toggleConnection() }) {
                    Image(systemName: ntfyClient.isConnected ? "stop.fill" : "play.fill")
                }
                .buttonStyle(.borderless)
                .help(ntfyClient.isConnected ? "Disconnect" : "Connect")
            }
            
            Spacer()
            
            Button(action: { NSApp.terminate(nil) }) {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func clearAllMessages() {
        ntfyClient.messages.removeAll()
        NotificationManager.shared.clearAllNotifications()
    }
    
    private func toggleConnection() {
        if ntfyClient.isConnected {
            ntfyClient.disconnect()
        } else {
            ntfyClient.connect()
        }
    }
}

struct MessageRow: View {
    let message: NtfyMessage
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var isHovered = false
    
    private var priorityColor: Color {
        guard let priority = message.priority else { return .secondary }
        switch priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .blue
        case 2: return .secondary
        case 1: return .gray
        default: return .secondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(message.title ?? message.topic)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(formatTimestamp(message.time))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    if settingsManager.topics.count > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 9))
                            Text(message.topic)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            if let messageText = message.message {
                Text(messageText)
                    .font(.system(size: 12))
                    .lineLimit(4)
                    .foregroundColor(.primary)
                    .lineSpacing(2)
            }
            
            HStack(spacing: 6) {
                if let tags = message.tags, !tags.isEmpty {
                    ForEach(tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                    }
                    
                    if tags.count > 3 {
                        Text("+\(tags.count - 3)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let priority = message.priority, priority >= 4 {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 10))
                        Text(priority == 5 ? "Urgent" : "High")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(priorityColor)
                }
            }
            
            if let clickURL = message.click, let _ = URL(string: clickURL) {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 10))
                    Text(clickURL)
                        .font(.system(size: 10))
                        .lineLimit(1)
                }
                .foregroundColor(.accentColor)
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(NSColor.controlBackgroundColor) : Color(NSColor.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
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
