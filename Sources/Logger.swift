import Foundation

class Logger {
    static let shared = Logger()
    
    private let logPath: String
    private let dateFormatter: DateFormatter
    
    private init() {
        logPath = NSHomeDirectory() + "/Library/Logs/NtfyTray.log"
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
    }
    
    func log(_ message: String, file: String = #file, function: String = #function) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = dateFormatter.string(from: Date())
        let logMessage = "[\(timestamp)] [\(fileName)] \(message)\n"
        
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: logPath))
            }
        }
    }
}
