import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var ntfyClient: NtfyClient
    @Environment(\.dismiss) private var dismiss
    
    @State private var serverURL: String = ""
    @State private var topics: [String] = []
    @State private var newTopic: String = ""
    @State private var useAuth: Bool = false
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var selectedTab: SettingsTab = .server
    
    enum SettingsTab: String, CaseIterable {
        case server = "Server"
        case topics = "Topics"
        case notifications = "Notifications"
        case general = "General"
        
        var icon: String {
            switch self {
            case .server: return "server.rack"
            case .topics: return "tray.full"
            case .notifications: return "bell.badge"
            case .general: return "gear"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            HStack(spacing: 0) {
                sidebarView
                    .frame(width: 160)
                
                Divider()
                
                contentView
                    .frame(maxWidth: .infinity)
            }
            
            Divider()
            
            footerView
        }
        .frame(width: 560, height: 440)
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "bell.circle.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text("Ntfy Tray Settings")
                .font(.headline)
            
            Spacer()
            
            connectionStatusBadge
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var connectionStatusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ntfyClient.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(ntfyClient.isConnected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var sidebarView: some View {
        VStack(spacing: 2) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .frame(width: 16)
                        Text(tab.rawValue)
                            .font(.system(size: 13))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(6)
                    .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                case .server:
                    serverContent
                case .topics:
                    topicsContent
                case .notifications:
                    notificationsContent
                case .general:
                    generalContent
                }
            }
            .padding(20)
        }
    }
    
    private var serverContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Server Configuration", icon: "server.rack")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Server URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                    TextField("ntfy.sh", text: $serverURL)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                
                Text("Enter your ntfy server address (e.g., ntfy.sh or your-server.com)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            sectionTitle("Authentication", icon: "person.badge.key.fill")
            
            Toggle(isOn: $useAuth) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use Authentication")
                        .font(.body)
                    Text("Enable if the server requires login")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            if useAuth {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.secondary)
                            TextField("Username", text: $username)
                                .textFieldStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.secondary)
                            SecureField("Password", text: $password)
                                .textFieldStyle(.plain)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var topicsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Subscribed Topics", icon: "tray.full")
            
            HStack {
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.secondary)
                    TextField("Enter topic name", text: $newTopic)
                        .textFieldStyle(.plain)
                        .onSubmit { addTopic() }
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                
                Button(action: addTopic) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .disabled(newTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            if !topics.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(topics.enumerated()), id: \.offset) { index, topic in
                        HStack {
                            Image(systemName: "tray")
                                .foregroundColor(.accentColor)
                                .font(.caption)
                            
                            Text(topic)
                                .font(.body)
                            
                            Spacer()
                            
                            Button(action: { removeTopic(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No topics configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Add topics above to start receiving notifications")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        }
    }
    
    private var notificationsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("System Notification Permission", icon: "lock.shield")
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: NotificationManager.shared.hasPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .foregroundColor(NotificationManager.shared.hasPermission ? .green : .orange)
                        
                        Text(NotificationManager.shared.hasPermission ? "Permission Granted" : "Permission Required")
                            .font(.body)
                    }
                    
                    Text(NotificationManager.shared.hasPermission 
                         ? "System notifications are enabled"
                         : "Enable notifications to receive alerts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !NotificationManager.shared.hasPermission {
                    Button(action: {
                        NotificationManager.shared.requestAuthorization()
                    }) {
                        Text("Grant Permission")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(NotificationManager.shared.hasPermission ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(NotificationManager.shared.hasPermission ? Color.green.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
            )
            
            if !NotificationManager.shared.hasPermission && NotificationManager.shared.permissionRequested {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("If you denied permission, you can enable it in System Settings > Notifications")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Button(action: {
                    NotificationManager.shared.openSystemNotificationSettings()
                }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Open System Settings")
                    }
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
            
            Divider()
            
            sectionTitle("Notification Settings", icon: "bell.badge")
            
            Toggle(isOn: $settingsManager.soundEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "speaker.wave.2")
                            .foregroundColor(.secondary)
                        Text("Play Sound")
                    }
                    Text("Play a sound when notifications arrive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Toggle(isOn: $settingsManager.showBadgeCount) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.secondary)
                        Text("Show Badge Count")
                    }
                    Text("Display unread message count in menu bar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            NotificationManager.shared.checkAuthorizationStatus()
        }
    }
    
    private var generalContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Connection", icon: "wifi")
            
            Toggle(isOn: $settingsManager.autoReconnect) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.secondary)
                        Text("Auto-Reconnect")
                    }
                    Text("Automatically reconnect if connection is lost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Toggle(isOn: $settingsManager.launchAtLogin) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "power")
                            .foregroundColor(.secondary)
                        Text("Launch at Login")
                    }
                    Text("Start Ntfy Tray when you log in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Button(action: resetSettings) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset All Settings")
                }
                .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
    }
    
    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
        }
    }
    
    private var footerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button("Save") {
                saveSettings()
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func loadCurrentSettings() {
        serverURL = settingsManager.serverURL
        topics = settingsManager.topics
        useAuth = settingsManager.useAuth
        username = settingsManager.username
        password = settingsManager.password
    }
    
    private func addTopic() {
        let trimmed = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !topics.contains(trimmed) {
            withAnimation {
                topics.append(trimmed)
            }
            newTopic = ""
        }
    }
    
    private func removeTopic(at index: Int) {
        guard index >= 0 && index < topics.count else { return }
        _ = withAnimation {
            topics.remove(at: index)
        }
    }
    
    private func saveSettings() {
        settingsManager.serverURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        settingsManager.topics = topics
        settingsManager.useAuth = useAuth
        settingsManager.username = username
        settingsManager.password = password
        
        if settingsManager.isConfigured {
            ntfyClient.connect()
        } else {
            ntfyClient.disconnect()
        }
    }
    
    private func resetSettings() {
        settingsManager.reset()
        loadCurrentSettings()
    }
}
