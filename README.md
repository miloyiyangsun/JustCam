# JustCam - Ultra-minimal RAW Camera

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg" alt="Swift 5.0">
  <img src="https://img.shields.io/badge/iOS-16%2B-blue.svg" alt="iOS 16+">
  <img src="https://img.shields.io/badge/RAW-DNG-red.svg" alt="RAW DNG">
  <img src="https://img.shields.io/badge/MetalKit-2025-green.svg" alt="MetalKit 2025">
</p>

> **极致简约的RAW相机应用** - 专为iPhone 13 mini优化的纯RAW拍摄体验

## 🎯 核心特性

| 特性 | 描述 |
|---|---|
| **💯 极简设计** | 单屏界面，无广告，无订阅 |
| **📷 纯RAW输出** | 仅DNG格式，25MB/张，零压缩 |
| **⚡ 实时预览** | 2025 Apple官方MetalKit管线，60fps |
| **🎯 13mini优化** | 专为iPhone 13 mini深度调校 |

## 🚀 技术亮点

### 2025 Apple官方RAW预览系统
```swift
// 实时YUV处理 + 3D-LUT
let renderer = RAWPreviewRenderer(metalView: view)
renderer.render(sampleBuffer: buffer, to: metalView)
```

- **MetalKit实时渲染**: 60fps硬件加速
- **中性3D-LUT**: 32x32x32线性映射，保持原始质感
- **YUV 420v格式**: 最小延迟，最佳性能

### 智能防抖机制
- **点击防抖**: 防止连续快速切换相机
- **生命周期管理**: 前后台平滑切换，零卡顿
- **线程安全**: SessionStateManager确保配置安全

### 所见即所得RAW
- **色调曲线修复**: 解决Apple RAW过曝/过暗问题
- **自动曝光系统**: ISO/快门/白平衡全自动
- **实时参数显示**: 拍摄前可见所有EXIF数据

## 📱 用户界面

### 手势控制
- **单击**: 对焦 + 测光
- **双击**: 切换3x3网格
- **长按**: 锁定对焦/曝光

### 控制布局
```
┌─────────────────────────────┐
│  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  │
│                             │
│         [📷]                │
│                             │
│ [🔁]      [🔘]      [🔍]    │
└─────────────────────────────┘
```

- **左上角**: 前后摄像头切换
- **底部中心**: 快门按钮
- **右下角**: 变焦条 (0.5×,1×,2×,3×,5×)

## ⚙️ 技术规格

| 项目 | 规格 |
|---|---|
| **最低支持** | iOS 16.0+ |
| **设备要求** | iPhone 13 mini (优化) |
| **输出格式** | DNG (Adobe RAW) |
| **文件大小** | ~25MB/张 |
| **预览延迟** | <16ms |
| **拍摄延迟** | <100ms |

## 🛠️ 开发环境

### 系统要求
```bash
# 构建命令
xcodebuild -scheme JustCam -configuration Debug build
xcodebuild test -scheme JustCam -destination 'platform=iOS Simulator,name=iPhone 16'
```

### 技术栈
- **语言**: Swift 5.0
- **UI框架**: SwiftUI
- **相机框架**: AVFoundation
- **渲染框架**: MetalKit
- **图像处理**: CoreImage
- **零第三方依赖**

## 🚀 快速开始

### 1. 克隆项目
```bash
git clone https://github.com/miloyiyangsun/JustCam.git
cd JustCam
```

### 2. 打开项目
```bash
open JustCam.xcodeproj
```

### 3. 运行应用
- 选择目标设备 (推荐: iPhone 16 模拟器)
- 点击运行 (⌘R)

## 📊 性能基准

| 操作 | 耗时 | 备注 |
|---|---|---|
| **应用启动** | <1s | 冷启动优化 |
| **相机切换** | <500ms | 防抖机制 |
| **前后台切换** | <200ms | 生命周期管理 |
| **RAW保存** | <2s | 25MB文件 |

## 🔍 架构设计

### 核心模块
```
JustCam/
├── CameraModel.swift          # 相机业务逻辑
├── CameraView.swift           # SwiftUI界面
├── RAWPreviewRenderer.swift   # MetalKit渲染
├── SessionStateManager.swift  # 线程安全管理
├── CameraLog.swift           # 性能日志
└── raw_style.cube            # 中性3D-LUT
```

### 设计模式
- **MVVM**: SwiftUI数据绑定
- **单例模式**: 相机管理
- **观察者模式**: 生命周期事件
- **队列模式**: 线程安全操作

## 🎨 自定义配置

### 3D-LUT自定义
编辑 `raw_style.cube` 文件可调整预览风格：
```
# 中性线性映射 (保持RAW原始质感)
TITLE "Neutral RAW Preview"
LUT_3D_SIZE 32
DOMAIN_MIN 0.0 0.0 0.0
DOMAIN_MAX 1.0 1.0 1.0
```

### 变焦级别配置
在 `CameraModel.swift` 中修改 `availableZoomLevels`:
```swift
@Published var availableZoomLevels: [Double] = [0.5, 1.0, 2.0, 3.0, 5.0]
```

## 🐛 故障排除

### 常见问题

**Q: 相机黑屏**
- 检查相机权限
- 重启应用
- 查看日志: `CameraLog.log`

**Q: RAW文件过曝**
- 确认使用最新版本
- 检查自动曝光是否启用
- 手动调整测光点

**Q: 预览延迟**
- 关闭其他应用
- 检查设备性能模式
- 降低预览分辨率

### 调试模式
```swift
// 开启详细日志
CameraLog.enabled = true
```

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 联系

- **项目**: [GitHub Issues](https://github.com/miloyiyangsun/JustCam/issues)
- **邮箱**: miloyiyangsun@gmail.com

---

<p align="center">
  Made with ❤️ for iPhone 13 mini users
</p>