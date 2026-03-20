import Foundation
import Combine

struct NtfyMessage: Codable, Identifiable {
    let id: String
    let time: Int64
    let event: String
    let topic: String
    let message: String?
    let title: String?
    let tags: [String]?
    let priority: Int?
    let click: String?
}

class NtfyClient: NSObject, ObservableObject, URLSessionWebSocketDelegate {
    static let shared = NtfyClient()
    
    @Published var isConnected = false
    @Published var messages: [NtfyMessage] = []
    @Published var connectionError: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let settingsManager = SettingsManager.shared
    private let notificationManager = NotificationManager.shared
    private let logger = Logger.shared
    private var reconnectTimer: Timer?
    private var keepaliveTimer: Timer?
    private var isManuallyDisconnected = false
    private var isConnecting = false
    private var isReconnecting = false
    private let delegateQueue = OperationQueue()
    private var reconnectAttempts = 0
    private let maxReconnectDelay: TimeInterval = 300
    
    private override init() {
        super.init()
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.name = "com.ntfytray.websocket"
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 0
        config.waitsForConnectivity = true
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: delegateQueue)
    }
    
    func connect() {
        guard !isConnecting else { return }
        
        isManuallyDisconnected = true
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        guard let url = buildWebSocketURL() else {
            DispatchQueue.main.async { [weak self] in
                self?.connectionError = "Invalid server URL or no topics configured"
            }
            return
        }
        
        isManuallyDisconnected = false
        isConnecting = true
        isReconnecting = false
        DispatchQueue.main.async { [weak self] in
            self?.connectionError = nil
        }
        
        var request = URLRequest(url: url)
        if let authHeader = settingsManager.authHeader {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        webSocketTask = urlSession?.webSocketTask(with: request)
        logger.log("Connecting to WebSocket: \(url)")
        webSocketTask?.resume()
        listenForMessages()
    }
    
    func disconnect() {
        isManuallyDisconnected = true
        isConnecting = false
        isReconnecting = false
        reconnectAttempts = 0
        
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        keepaliveTimer?.invalidate()
        keepaliveTimer = nil
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
        }
    }
    
    private func buildWebSocketURL() -> URL? {
        let serverURL = settingsManager.serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let topics = settingsManager.topics
        
        guard !serverURL.isEmpty, !topics.isEmpty else { return nil }
        
        var urlString = serverURL
            .replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        
        if !urlString.hasPrefix("ws://") && !urlString.hasPrefix("wss://") {
            urlString = "wss://\(urlString)"
        }
        
        let topicsString = topics.joined(separator: ",")
        urlString += "/\(topicsString)/ws"
        
        return URL(string: urlString)
    }
    
    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            if self.isManuallyDisconnected { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.listenForMessages()
            case .failure(let error):
                self.logger.log("WebSocket receive error: \(error)")
                DispatchQueue.main.async { [weak self] in
                    self?.isConnected = false
                    self?.connectionError = error.localizedDescription
                }
                self.scheduleReconnect()
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            parseAndProcessMessage(text)
        case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
                parseAndProcessMessage(text)
            }
        @unknown default:
            break
        }
    }
    
    private func parseAndProcessMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = json["event"] as? String else { return }
        
        if event == "open" {
            logger.log("Received open event from server")
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = true
                self?.connectionError = nil
            }
            reconnectAttempts = 0
            startKeepaliveTimer()
        } else if event == "keepalive" {
            resetKeepaliveTimer()
        } else if event == "message" {
            do {
                let decoder = JSONDecoder()
                let message = try decoder.decode(NtfyMessage.self, from: data)
                
                DispatchQueue.main.async { [weak self] in
                    self?.messages.insert(message, at: 0)
                    if self?.messages.count ?? 0 > 100 {
                        self?.messages.removeLast()
                    }
                }
                
                notificationManager.showNotification(for: message)
            } catch {
                logger.log("Failed to decode message: \(error)")
            }
        }
    }
    
    private func startKeepaliveTimer() {
        keepaliveTimer?.invalidate()
        DispatchQueue.main.async { [weak self] in
            self?.keepaliveTimer = Timer.scheduledTimer(withTimeInterval: 45, repeats: true) { _ in
                self?.sendPing()
            }
        }
    }
    
    private func sendPing() {
        webSocketTask?.sendPing { [weak self] error in
            if let error = error {
                self?.logger.log("Ping failed: \(error)")
                self?.scheduleReconnect()
            }
        }
    }
    
    private func resetKeepaliveTimer() {
        startKeepaliveTimer()
    }
    
    private func scheduleReconnect() {
        guard !isManuallyDisconnected else { return }
        guard !isReconnecting else { return }
        guard !isConnecting else { return }
        isReconnecting = true
        
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
        }
        
        reconnectTimer?.invalidate()
        
        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(min(reconnectAttempts, 8))), maxReconnectDelay)
        logger.log("Scheduling reconnect attempt \(reconnectAttempts) in \(delay)s")
        
        DispatchQueue.main.async { [weak self] in
            self?.reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                guard let self = self else { return }
                self.isReconnecting = false
                if !self.isManuallyDisconnected && self.settingsManager.autoReconnect {
                    self.connect()
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        guard !isManuallyDisconnected else { return }
        
        logger.log("WebSocket opened with protocol: \(`protocol` ?? "none")")
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = true
            self?.connectionError = nil
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        guard !isManuallyDisconnected else { return }
        
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "none"
        logger.log("WebSocket closed with code: \(closeCode), reason: \(reasonString)")
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
            self?.isConnecting = false
        }
        scheduleReconnect()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard !isManuallyDisconnected else { return }
        
        if let error = error {
            logger.log("WebSocket task completed with error: \(error)")
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = false
                self?.isConnecting = false
                self?.connectionError = error.localizedDescription
            }
            scheduleReconnect()
        } else {
            logger.log("WebSocket task completed without error")
        }
    }
}
