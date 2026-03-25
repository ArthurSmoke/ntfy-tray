import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var serverURL: String {
        didSet { save() }
    }
    
    @Published var topics: [String] {
        didSet { save() }
    }
    
    @Published var username: String {
        didSet { save() }
    }
    
    @Published var password: String {
        didSet { save() }
    }
    
    @Published var useAuth: Bool {
        didSet { save() }
    }
    
    @Published var showBadgeCount: Bool {
        didSet { save() }
    }
    
    @Published var autoReconnect: Bool {
        didSet { save() }
    }
    
    @Published var soundEnabled: Bool {
        didSet { save() }
    }
    
    private var settingsFileURL: URL {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let ntfyDirectory = homeDirectory.appendingPathComponent(".ntfy")
        
        if !FileManager.default.fileExists(atPath: ntfyDirectory.path) {
            try? FileManager.default.createDirectory(at: ntfyDirectory, withIntermediateDirectories: true)
        }
        
        return ntfyDirectory.appendingPathComponent("settings.json")
    }
    
    private struct SettingsData: Codable {
        var serverURL: String
        var topics: [String]
        var username: String
        var password: String
        var useAuth: Bool
        var showBadgeCount: Bool
        var autoReconnect: Bool
        var soundEnabled: Bool
    }
    
    private init() {
        let data = Self.load()
        self.serverURL = data.serverURL
        self.topics = data.topics
        self.username = data.username
        self.password = data.password
        self.useAuth = data.useAuth
        self.showBadgeCount = data.showBadgeCount
        self.autoReconnect = data.autoReconnect
        self.soundEnabled = data.soundEnabled
    }
    
    private static func load() -> SettingsData {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let ntfyDirectory = homeDirectory.appendingPathComponent(".ntfy")
        let settingsFile = ntfyDirectory.appendingPathComponent("settings.json")
        
        if FileManager.default.fileExists(atPath: settingsFile.path),
           let data = try? Data(contentsOf: settingsFile),
           let settings = try? JSONDecoder().decode(SettingsData.self, from: data) {
            return settings
        }
        
        return SettingsData(
            serverURL: "ntfy.sh",
            topics: [],
            username: "",
            password: "",
            useAuth: false,
            showBadgeCount: true,
            autoReconnect: true,
            soundEnabled: true
        )
    }
    
    private func save() {
        let data = SettingsData(
            serverURL: serverURL,
            topics: topics,
            username: username,
            password: password,
            useAuth: useAuth,
            showBadgeCount: showBadgeCount,
            autoReconnect: autoReconnect,
            soundEnabled: soundEnabled
        )
        
        if let jsonData = try? JSONEncoder().encode(data) {
            try? jsonData.write(to: settingsFileURL)
        }
    }
    
    var isConfigured: Bool {
        !serverURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !topics.isEmpty
    }
    
    var authHeader: String? {
        guard useAuth, !username.isEmpty else { return nil }
        let credentials = "\(username):\(password)"
        guard let data = credentials.data(using: .utf8) else { return nil }
        return "Basic \(data.base64EncodedString())"
    }
    
    func addTopic(_ topic: String) {
        let trimmed = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !topics.contains(trimmed) {
            topics.append(trimmed)
        }
    }
    
    func removeTopic(_ topic: String) {
        topics.removeAll { $0 == topic }
    }
    
    func removeTopic(at index: Int) {
        guard index >= 0 && index < topics.count else { return }
        topics.remove(at: index)
    }
    
    func reset() {
        serverURL = "ntfy.sh"
        topics = []
        username = ""
        password = ""
        useAuth = false
        showBadgeCount = true
        autoReconnect = true
        soundEnabled = true
    }
    
}