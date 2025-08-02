import SwiftUI

@main
struct JustCamApp: App {
    init() {
        CameraLog.initialize()
        
        // 测试log文件写入
        CameraLog.log("🚀 JustCamApp initialized on iPhone 13 mini")
        CameraLog.log("📁 Log file path: \(CameraLog.getLogFilePath())")
        
        // 延迟显示log文件内容
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let logContent = CameraLog.readLogFile()
            print("📄 Current log file content:")
            print(logContent)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            CameraView()
                .onAppear {
                    CameraLog.log("JustCamApp appeared")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        // 延迟检查预览层状态
                    }
                }
        }
    }
}