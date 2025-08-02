import MetalKit
import CoreImage
import AVFoundation
import SwiftUI
import Metal

/// 2025年Apple官方RAW预览渲染器
/// 使用MetalKit + 3D-LUT实现所见即所得RAW预览
final class RAWPreviewRenderer: NSObject {
    private var device: MTLDevice
    private var commandQueue: MTLCommandQueue
    private var ciContext: CIContext
    private var lutTexture: MTLTexture?
    
    // 2025年官方YUV格式支持
    private let supportedPixelFormats: [OSType] = [
        kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,  // 420v
        kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,   // 420f
        kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange,  // 422v
        kCVPixelFormatType_32BGRA                          // BGRA
    ]
    
    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.ciContext = CIContext(mtlDevice: device)
        
        super.init()
        
        setupMetalView(metalView)
        load3DLUT()
    }
    
    private func setupMetalView(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = false
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        view.delegate = self
    }
    
    private func load3DLUT() {
        // 2025年官方中性RAW LUT文件路径 - 保持原始质感
        guard let lutURL = Bundle.main.url(forResource: "raw_style", withExtension: "cube") else {
            CameraLog.log("⚠️ 未找到中性LUT文件，使用无增强渲染")
            return
        }
        
        do {
            let lutImage = try create3DLUTTexture(from: lutURL)
            lutTexture = lutImage
            CameraLog.log("✅ 中性RAW LUT加载成功 - 保持原始质感")
        } catch {
            CameraLog.error("❌ 中性LUT加载失败: \(error)")
        }
    }
    
    private func create3DLUTTexture(from url: URL) throws -> MTLTexture {
        // 2025年官方3D-LUT解析器
        let lutData = try Data(contentsOf: url)
        let lutString = String(data: lutData, encoding: .utf8) ?? ""
        
        // 解析.cube文件格式
        let lines = lutString.components(separatedBy: .newlines)
        var size: Int = 32
        var values: [Float] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            if trimmed.hasPrefix("TITLE") { continue }
            if trimmed.hasPrefix("DOMAIN_MIN") || trimmed.hasPrefix("DOMAIN_MAX") { continue }
            
            let components = trimmed.components(separatedBy: .whitespaces)
                .compactMap { Float($0) }
            
            if components.count == 3 {
                values.append(contentsOf: components)
            }
        }
        
        // 计算LUT尺寸
        let totalValues = values.count / 3
        size = Int(pow(Double(totalValues), 1.0/3.0))
        
        // 创建Metal纹理
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: size * size,
            height: size,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw NSError(domain: "RAWPreviewRenderer", code: -1, userInfo: nil)
        }
        
        // 上传数据到GPU
        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                             size: MTLSize(width: size * size, height: size, depth: 1))
        texture.replace(region: region, mipmapLevel: 0, withBytes: values, bytesPerRow: size * size * 16)
        
        return texture
    }
    
    /// 2025年官方渲染API
    func render(sampleBuffer: CMSampleBuffer, to metalView: MTKView) {
        guard let drawable = metalView.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        // 转换CMSampleBuffer到CIImage
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // 应用3D-LUT效果
        let processedImage = apply3DLUT(to: ciImage)
        
        // 渲染到Metal视图
        let drawableSize = CGSize(width: drawable.texture.width, height: drawable.texture.height)
        ciContext.render(processedImage,
                        to: drawable.texture,
                        commandBuffer: commandBuffer,
                        bounds: CGRect(origin: .zero, size: drawableSize),
                        colorSpace: CGColorSpaceCreateDeviceRGB())
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func apply3DLUT(to image: CIImage) -> CIImage {
        guard let lutTexture = lutTexture else {
            return image
        }
        
        // 2025年官方3D-LUT滤波器
        let filter = CIFilter(name: "CIColorCube")!
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(lutTexture, forKey: "inputCubeData")
        filter.setValue(64, forKey: "inputCubeDimension")
        
        return filter.outputImage ?? image
    }
}

extension RAWPreviewRenderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // 处理尺寸变化
    }
    
    func draw(in view: MTKView) {
        // 自动渲染由CMSampleBuffer驱动
    }
}