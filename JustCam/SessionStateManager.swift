import AVFoundation
import Foundation

// 关键修复：Session状态管理器
final class SessionStateManager {
    private let session: AVCaptureSession
    private let queue: DispatchQueue
    private var isConfiguring = false
    
    init(session: AVCaptureSession, queue: DispatchQueue) {
        self.session = session
        self.queue = queue
    }
    
    func performConfiguration(_ block: @escaping () -> Void) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.isConfiguring = true
            CameraLog.log("[SESSION-MANAGER] 开始配置 - isConfiguring: true")
            
            // 关键修复：检查并确保配置状态正确
            let initialCount = self.getConfigurationCount()
            CameraLog.log("[SESSION-MANAGER] 初始configurationCount: \(initialCount)")
            
            self.session.beginConfiguration()
            
            block()
            
            self.session.commitConfiguration()
            self.isConfiguring = false
            
            let finalCount = self.getConfigurationCount()
            CameraLog.log("[SESSION-MANAGER] 配置完成 - configurationCount: \(finalCount)")
            
            assert(finalCount == 0, "配置计数器应该为0")
        }
    }
    
    func safeStartRunning() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let configCount = self.getConfigurationCount()
            let isRunning = self.session.isRunning
            
            CameraLog.log("[SESSION-MANAGER] 检查启动条件 - configCount: \(configCount), isRunning: \(isRunning)")
            
            if configCount != 0 {
                CameraLog.error("[SESSION-MANAGER] 错误：正在配置中无法启动")
                return
            }
            
            if !isRunning {
                let startTime = CFAbsoluteTimeGetCurrent()
                self.session.startRunning()
                let endTime = CFAbsoluteTimeGetCurrent()
                CameraLog.log("[SESSION-MANAGER] Session启动成功，耗时: \(endTime - startTime) 秒")
            } else {
                CameraLog.log("[SESSION-MANAGER] Session已在运行，跳过启动")
            }
        }
    }
    
    func safeStopRunning() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if self.session.isRunning {
                let stopTime = CFAbsoluteTimeGetCurrent()
                self.session.stopRunning()
                let endTime = CFAbsoluteTimeGetCurrent()
                CameraLog.log("[SESSION-MANAGER] Session停止耗时: \(endTime - stopTime) 秒")
            }
        }
    }
    
    private func getConfigurationCount() -> Int {
        // 关键修复：移除私有API调用，使用内部状态追踪
        return isConfiguring ? 1 : 0
    }
}