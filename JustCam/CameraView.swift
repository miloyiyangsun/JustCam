import SwiftUI
import AVFoundation
import Photos

struct CameraView: View {
    @StateObject private var cameraModel = CameraModel()
    @State private var showGrid = false
    @State private var showDigitalLabel = false
    @State private var showFlashAnimation = false
    @State private var isCapturing = false
    @State private var focusPoint: CGPoint?
    @State private var showFocusIndicator = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Camera preview layer
                CameraPreview(session: cameraModel.session, cameraModel: cameraModel)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { location in
                        CameraLog.log("Tap to focus at: \(location)")
                        focusPoint = location
                        showFocusIndicator = true
                        cameraModel.focusAndExpose(at: location, in: geometry.size)
                        
                        // 3秒后隐藏对焦指示器
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showFocusIndicator = false
                        }
                    }
                    .onTapGesture(count: 2) {
                        CameraLog.log("Double tap detected - toggling grid: \(!showGrid)")
                        showGrid.toggle()
                    }
                    .onAppear {
                        // 监听照片保存完成通知
                        NotificationCenter.default.addObserver(
                            forName: Notification.Name("PhotoSaved"),
                            object: nil,
                            queue: .main
                        ) { _ in
                            isCapturing = false
                        }
                    }
                
                // Grid overlay
                if showGrid {
                    GridOverlay()
                }
                
                // Digital zoom label
                if showDigitalLabel {
                    Text("Digital")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(4)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(4)
                        .position(x: geometry.size.width / 2, y: 50)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showDigitalLabel = false
                            }
                        }
                }
                
                // Flash animation overlay
                if showFlashAnimation {
                    Color.white
                        .edgesIgnoringSafeArea(.all)
                        .opacity(0.9)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.1), value: showFlashAnimation)
                }
                
                // Focus indicator
                if let focusPoint = focusPoint, showFocusIndicator {
                    FocusIndicator(position: focusPoint)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: showFocusIndicator)
                }
                
                // Bottom controls
                VStack {
                    Spacer()
                    
                    HStack {
                        // Shutter button (centered)
                        Button(action: {
                            CameraLog.log("Shutter button pressed")
                            isCapturing = true
                            triggerFlashAnimation()
                            cameraModel.capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 60, height: 60)
                                    .background(Circle().fill(Color.white.opacity(0.1)))
                                
                                if isCapturing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                        }
                        .disabled(isCapturing)
                        .opacity(isCapturing ? 0.6 : 1.0)
                        
                        Spacer()
                        
                        // Zoom strip (right-aligned)
                        VStack(spacing: 12) {
                            ForEach(cameraModel.availableZoomLevels, id: \.self) { zoom in
                                Button(action: {
                                    CameraLog.log("Zoom button tapped: \(zoom)x")
                                    let isDigital = cameraModel.setZoom(zoom)
                                    if isDigital {
                                        CameraLog.log("Digital zoom activated")
                                        showDigitalLabel = true
                                    }
                                }) {
                                    Text("\(zoom, specifier: "%g")×")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(cameraModel.currentZoom == zoom ? .yellow : .white)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                    .background(
                        Rectangle()
                            .fill(Color.black.opacity(0.4))
                            .frame(height: 90)
                            .edgesIgnoringSafeArea(.bottom)
                    )
                }
                
                // 右上角控制按钮：翻转相机和闪光灯
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            CameraLog.log("Camera flip button tapped")
                            cameraModel.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(8)
                        }
                        .padding(.trailing, 10)
                        
                        Button(action: {
                            CameraLog.log("Torch button tapped")
                            cameraModel.toggleTorch()
                        }) {
                            Image(systemName: cameraModel.isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(8)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                }
                
                // 左下角图库跳转按钮
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            CameraLog.log("📱 Opening photo library")
                            openPhotoLibrary()
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(8)
                        }
                        .padding(.leading, 20)
                        .padding(.bottom, 100)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func openPhotoLibrary() {
        let photosURL = URL(string: "photos-redirect://") ?? URL(string: "photos://") ?? URL(string: "mobilephotos://")
        
        if let url = photosURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    CameraLog.log("✅ Successfully opened photo library")
                } else {
                    CameraLog.error("❌ Failed to open photo library")
                }
            }
        } else {
            CameraLog.error("❌ Cannot open photo library URL")
        }
    }
    
    private func triggerFlashAnimation() {
        CameraLog.log("✨ Triggering flash animation")
        
        withAnimation(.easeInOut(duration: 0.05)) {
            showFlashAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.05)) {
                showFlashAnimation = false
            }
            CameraLog.log("✨ Flash animation completed")
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let cameraModel: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        CameraLog.log("=== PREVIEW LAYER SYSTEMATIC DIAGNOSIS ===")
        
        let view = UIView()
        view.backgroundColor = .black
        
        // 关键修复：确保视图有初始尺寸
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        CameraLog.log("[PREVIEW-FIX-001] UIView初始化尺寸: \(view.frame)")
        
        #if targetEnvironment(simulator)
        CameraLog.log("[PREVIEW-FIX-002] 模拟器环境 - 创建增强预览")
        
        let previewContainer = UIView()
        previewContainer.backgroundColor = .darkGray
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewContainer)
        
        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        #else
        // 关键修复：完全移除Session启动逻辑，让CameraModel完全控制
        CameraLog.log("[PREVIEW-FIX-003] 真实设备 - CameraModel完全控制Session")
        
        // 🔧 **关键修复**：使用照片模式预览设置
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.name = "CameraPreviewLayer"
        
        // 🔧 **照片模式预览**：使用完整画面而非裁剪
        previewLayer.videoGravity = .resizeAspect  // 保持完整画面，不裁剪
        previewLayer.frame = UIScreen.main.bounds
        previewLayer.backgroundColor = UIColor.clear.cgColor
        
        CameraLog.log("[PREVIEW-FIX-CONFIG] PreviewLayer创建完成，使用照片模式预览(.resizeAspect)")
        
        // 添加预览层
        view.layer.addSublayer(previewLayer)
        view.layer.masksToBounds = true
        
        // 存储引用
        context.coordinator.previewLayer = previewLayer
        #endif
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        CameraLog.log("=== PREVIEW LAYER UPDATE SYSTEMATIC FIX ===")
        
        let bounds = uiView.bounds
        CameraLog.log("[UPDATE-SYSTEM-001] UIView bounds: \(bounds)")
        CameraLog.log("[UPDATE-SYSTEM-002] UIView frame: \(uiView.frame)")
        
        // 关键修复：确保bounds不为零
        if bounds.width == 0 || bounds.height == 0 {
            CameraLog.log("[UPDATE-SYSTEM-003] ❌ 零尺寸检测，使用屏幕尺寸")
            let screenBounds = UIScreen.main.bounds
            uiView.frame = screenBounds
            CameraLog.log("[UPDATE-SYSTEM-004] 修正UIView尺寸: \(screenBounds)")
        }
        
        if let previewLayer = context.coordinator.previewLayer {
            CameraLog.log("[UPDATE-SYSTEM-005] 找到previewLayer")
            
            // 关键修复：确保frame同步
            let targetBounds = uiView.bounds
            if targetBounds != previewLayer.frame {
                previewLayer.frame = targetBounds
                CameraLog.log("[UPDATE-SYSTEM-006] PreviewLayer frame同步: \(targetBounds)")
            }
            
            // 关键修复：确保可见性
            previewLayer.isHidden = false
            previewLayer.opacity = 1.0
            previewLayer.backgroundColor = UIColor.clear.cgColor
            
            // 关键修复：强制刷新显示
            previewLayer.setNeedsDisplay()
            previewLayer.displayIfNeeded()
            
            // 验证连接状态
            if let connection = previewLayer.connection {
                CameraLog.log("[UPDATE-SYSTEM-007] 连接验证 - active: \(connection.isActive)")
                if !connection.isActive {
                    CameraLog.log("[UPDATE-SYSTEM-008] 重新启用连接")
                    connection.isEnabled = true
                }
            }
        } else {
            CameraLog.log("[UPDATE-SYSTEM-009] ❌ 未找到previewLayer，重新创建")
            
            // 关键修复：重新创建preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = uiView.bounds
            previewLayer.videoGravity = .resizeAspect
            previewLayer.backgroundColor = UIColor.clear.cgColor
            
            uiView.layer.addSublayer(previewLayer)
            context.coordinator.previewLayer = previewLayer
            
            CameraLog.log("[UPDATE-SYSTEM-010] PreviewLayer重新创建完成")
        }
        
        CameraLog.log("[PHOTO-MODE-PREVIEW] 照片模式预览更新完成 - 使用.resizeAspect确保完整画面")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(model: cameraModel)
    }
    
    class Coordinator: NSObject {
        var previewLayer: AVCaptureVideoPreviewLayer?
        weak var model: CameraModel?
        
        init(model: CameraModel) {
            self.model = model
            super.init()
            
            // 关键修复：监听应用状态变化
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appDidBecomeActive),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appWillResignActive),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc func appDidBecomeActive() {
            CameraLog.log("[BLACK-FIX-001] 应用恢复活跃，CameraModel完全处理Session管理")
            // 完全不移除任何操作，让CameraModel的生命周期管理处理
        }
        
        @objc func appWillResignActive() {
            CameraLog.log("[BLACK-FIX-002] 应用进入后台，保持Session运行")
            // 不停止Session，避免黑屏
        }
    }
}

struct GridOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            let thirdWidth = geometry.size.width / 3
            let thirdHeight = geometry.size.height / 3
            
            Path { path in
                // Vertical lines
                path.move(to: CGPoint(x: thirdWidth, y: 0))
                path.addLine(to: CGPoint(x: thirdWidth, y: geometry.size.height))
                path.move(to: CGPoint(x: 2 * thirdWidth, y: 0))
                path.addLine(to: CGPoint(x: 2 * thirdWidth, y: geometry.size.height))
                
                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: thirdHeight))
                path.addLine(to: CGPoint(x: geometry.size.width, y: thirdHeight))
                path.move(to: CGPoint(x: 0, y: 2 * thirdHeight))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 2 * thirdHeight))
            }
            .stroke(Color.white.opacity(0.6), lineWidth: 1)
        }
    }
}

struct FocusIndicator: View {
    let position: CGPoint
    
    var body: some View {
        ZStack {
            // 简化对焦框：只有外框，无十字线
            Rectangle()
                .stroke(Color.yellow, lineWidth: 2)
                .frame(width: 70, height: 70)
            
            Rectangle()
                .stroke(Color.yellow.opacity(0.6), lineWidth: 1)
                .frame(width: 50, height: 50)
        }
        .position(position)
        .scaleEffect(0.8)
    }
}