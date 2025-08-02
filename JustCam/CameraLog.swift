import Foundation
import os.log

struct CameraLog {
    private static let subsystem = "com.justcam"
    private static let category = "camera"
    
    private static let logger = Logger(subsystem: subsystem, category: category)
    
    static var logFileURL: URL? {
        let fileManager = FileManager.default
        
        // 使用caches目录而不是documents目录，确保可写入
        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        // 创建JustCam目录
        let justCamDirectory = cachesDirectory.appendingPathComponent("JustCamLogs")
        if !fileManager.fileExists(atPath: justCamDirectory.path) {
            try? fileManager.createDirectory(at: justCamDirectory, withIntermediateDirectories: true)
        }
        
        return justCamDirectory.appendingPathComponent("justcam_log.txt")
    }
    
    private static func clearLogFile() {
        guard let logFileURL = logFileURL else { return }
        
        do {
            try "".write(to: logFileURL, atomically: true, encoding: .utf8)
            logger.info("Log file cleared on app start")
            print("📝 Log file cleared at: \(logFileURL.path)")
        } catch {
            logger.error("Failed to clear log file: \(error.localizedDescription)")
            print("❌ Failed to clear log file: \(error.localizedDescription)")
        }
    }
    
    static func initialize() {
        clearLogFile()
        
        // 重要：记录log文件位置
        let logPath = getLogFilePath()
        print("📝 Log文件路径: \(logPath)")
        print("📱 请在Mac上查看: ~/Library/Developer/CoreSimulator/Devices/[设备ID]/data/Containers/Data/Application/[应用ID]/Library/Caches/JustCamLogs/justcam_log.txt")
        
        log("=== JustCam Started ===")
        log("📱 设备: iPhone 13 mini")
        log("📁 Log文件路径: \(logPath)")
        log("🔍 开始捕获preview层信息...")
    }
    
    static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(timestamp)] [\(fileName):\(line)] \(function): \(message)"
        
        logger.info("\(logMessage)")
        print("📱 \(logMessage)")  // 控制台输出
        
        guard let logFileURL = logFileURL else {
            print("❌ No log file URL available")
            return
        }
        
        // 确保log文件存在
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: logFileURL.path) {
            fileManager.createFile(atPath: logFileURL.path, contents: nil)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: logFileURL)
            fileHandle.seekToEndOfFile()
            if let data = (logMessage + "\n").data(using: .utf8) {
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } catch {
            print("❌ Failed to write log: \(error.localizedDescription)")
        }
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[ERROR] [\(timestamp)] [\(fileName):\(line)] \(function): \(message)"
        
        logger.error("\(logMessage)")
        print("❌ \(logMessage)")
        
        guard let logFileURL = logFileURL else { return }
        
        // 确保log文件存在
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil)
        }
        
        do {
            let fileHandle = try FileHandle(forWritingTo: logFileURL)
            fileHandle.seekToEndOfFile()
            if let data = (logMessage + "\n").data(using: .utf8) {
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } catch {
            logger.error("Failed to write error to log file: \(error.localizedDescription)")
            print("❌ Failed to write error to log file: \(error.localizedDescription)")
        }
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log("[DEBUG] \(message)", file: file, function: function, line: line)
        #endif
    }
    
    // 获取log文件路径用于调试
    static func getLogFilePath() -> String {
        return logFileURL?.path ?? "Log file path not available"
    }
    
    // 获取完整log文件信息
    static func getLogFileInfo() -> String {
        guard let logFileURL = logFileURL else { return "Log file not available" }
        
        let fileManager = FileManager.default
        var info = "📄 Log文件信息:\n"
        info += "路径: \(logFileURL.path)\n"
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: logFileURL.path)
            if let size = attributes[.size] as? Int64 {
                info += "大小: \(Double(size)/1024.0) KB\n"
            }
            if let creationDate = attributes[.creationDate] {
                info += "创建时间: \(creationDate)\n"
            }
            if let modificationDate = attributes[.modificationDate] {
                info += "修改时间: \(modificationDate)\n"
            }
        } catch {
            info += "获取文件信息失败: \(error.localizedDescription)\n"
        }
        
        return info
    }
    
    // 获取log文件内容用于调试
    static func readLogFile() -> String {
        guard let logFileURL = logFileURL else { return "Log file not available" }
        
        do {
            return try String(contentsOf: logFileURL, encoding: .utf8)
        } catch {
            return "Failed to read log file: \(error.localizedDescription)"
        }
    }
}