import SwiftUI

struct SettingsPanel: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var ntfyClient: NtfyClient
    
    @State private var serverURL: String = ""
    @State private var topics: [String] = []
    @State private var newTopic: String = ""
    @State private var useAuth: Bool = false
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var selectedSection: SettingsSection = .server
    
    enum SettingsSection: String, CaseIterable {
        case server = "Server"
        case topics = "Topics"
        case general = "General"
        
        var icon: String {
            switch self {
            case .server: return "server.rack"
            case .topics: return "tray.full"
            case .general: return "gear"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            HStack(alignment: .top, spacing: 0) {
                sectionPicker
                    .frame(width: 160)
                
                Divider()
                    .opacity(0.5)
                
                sectionContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Divider()
                .opacity(0.5)
            
            footer
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear { loadSettings() }
        .onReceive(NotificationCenter.default.publisher(for: .switchToSettings)) { _ in
            selectedSection = .server
        }
    }
    
    private var header: some View {
        HStack {
            Text("Settings")
                .font(.system(size: 20, weight: .semibold))
            
            Spacer()
            
            connectionBadge
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var connectionBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ntfyClient.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(ntfyClient.isConnected ? "Connected" : "Disconnected")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var sectionPicker: some View {
        VStack(spacing: 2) {
            ForEach(SettingsSection.allCases, id: \.self) { section in
                Button(action: { selectedSection = section }) {
                    HStack(spacing: 8) {
                        Image(systemName: section.icon)
                            .font(.system(size: 13))
                            .frame(width: 18)
                        
                        Text(section.rawValue)
                            .font(.system(size: 13, weight: selectedSection == section ? .medium : .regular))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedSection == section ? Color.blue.opacity(0.15) : Color.clear)
                    )
                    .foregroundColor(selectedSection == section ? .blue : .primary)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
    
    @ViewBuilder
    private var sectionContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                switch selectedSection {
                case .server:
                    serverSection
                case .topics:
                    topicsSection
                case .general:
                    generalSection
                }
            }
            .padding(24)
        }
    }
    
    private var serverSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Server Configuration", icon: "server.rack")
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Server URL")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("ntfy.sh", text: $serverURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                Text("Enter your ntfy server address")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            Divider()
            
            sectionHeader("Authentication", icon: "person.badge.key")
            
            Toggle(isOn: $useAuth) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use Authentication")
                        .font(.system(size: 13))
                    Text("Enable if server requires login")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            if useAuth {
                VStack(alignment: .leading, spacing: 14) {
                    inputField(title: "Username", icon: "person", text: $username, placeholder: "Username")
                    inputField(title: "Password", icon: "lock", text: $password, placeholder: "Password", isSecure: true)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Subscribed Topics", icon: "tray.full")
            
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("Enter topic name", text: $newTopic)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .onSubmit { addTopic() }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                Button(action: addTopic) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .disabled(newTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            if !topics.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(topics.enumerated()), id: \.offset) { index, topic in
                        HStack(spacing: 10) {
                            Image(systemName: "tray.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                            
                            Text(topic)
                                .font(.system(size: 13))
                            
                            Spacer()
                            
                            Button(action: { removeTopic(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                    }
                }
            } else {
                emptyTopicsView
            }
        }
    }
    
    private var emptyTopicsView: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("No topics configured")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Text("Add topics to receive notifications")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("System Permissions", icon: "lock.shield")
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: NotificationManager.shared.hasPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .foregroundColor(NotificationManager.shared.hasPermission ? .green : .orange)
                        
                        Text(NotificationManager.shared.hasPermission ? "Permission Granted" : "Permission Required")
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    Text(NotificationManager.shared.hasPermission ? "System notifications enabled" : "Enable notifications to receive alerts")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !NotificationManager.shared.hasPermission {
                    Button("Grant") {
                        NotificationManager.shared.requestAuthorization()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(NotificationManager.shared.hasPermission ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            )
            
            Divider()
            
            sectionHeader("Connection", icon: "wifi")
            
            Toggle(isOn: $settingsManager.autoReconnect) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto-Reconnect")
                        .font(.system(size: 13))
                    Text("Reconnect if connection lost")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Button(action: resetSettings) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset All Settings")
                }
                .foregroundColor(.red)
                .font(.system(size: 13))
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            NotificationManager.shared.checkAuthorizationStatus()
        }
    }
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.system(size: 14))
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
        }
    }
    
    private func inputField(title: String, icon: String, text: Binding<String>, placeholder: String, isSecure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                if isSecure {
                    SecureField(placeholder, text: text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                } else {
                    TextField(placeholder, text: text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private var footer: some View {
        HStack {
            Button("Cancel") {
                loadSettings()
            }
            .keyboardShortcut(.cancelAction)
            
            Spacer()
            
            Button("Save") {
                saveSettings()
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    private func loadSettings() {
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
        withAnimation {
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
        loadSettings()
    }
}
