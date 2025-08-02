# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**JustCam** is a SwiftUI-based iOS camera application project. This is a fresh project with minimal structure currently in place.

## Development Commands

### Build Commands
- **Build**: `xcodebuild -scheme JustCam -configuration Debug build`
- **Clean build**: `xcodebuild -scheme JustCam -configuration Debug clean build`
- **Run on simulator**: `xcodebuild -scheme JustCam -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15'`

### Testing Commands
- **Run all tests**: `xcodebuild test -scheme JustCam -destination 'platform=iOS Simulator,name=iPhone 15'`
- **Run specific test**: `xcodebuild test -scheme JustCam -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:TestTarget/TestClass/testMethod`

## Architecture

### Current Structure
- **Entry Point**: `JustCam/JustCamApp.swift` - Main SwiftUI app with `@main` annotation
- **Main View**: `JustCam/ContentView.swift` - Basic SwiftUI view with placeholder content
- **Assets**: `JustCam/Assets.xcassets/` - App icons and asset catalog
- **Previews**: `JustCam/Preview Content/` - SwiftUI preview assets

### Technology Stack
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Build System**: Xcode (project.pbxproj)
- **Target Platform**: iOS

## Project Configuration
- **Target**: JustCam (iOS application)
- **Build Configurations**: Debug, Release
- **Scheme**: JustCam (default scheme)

## Common Development Tasks

### Running the App
1. Open `JustCam.xcodeproj` in Xcode
2. Select target device/simulator
3. Run with ⌘+R or Product → Run

### Adding New Features
- Add new SwiftUI views in the `JustCam/` directory
- Update `ContentView.swift` for main interface changes
- Use Xcode's preview canvas for SwiftUI development

### Asset Management
- Add images/icons to `Assets.xcassets`
- Use SF Symbols via `Image(systemName:)` for system icons

• 项目目标（极简 UI、仅拍 RAW、无广告）
• 技术栈（SwiftUI、AVFoundation、无第三方库）
• 三步黄金流程：Explore → Plan → Code → Commit


# JustCam – Ultra-minimal RAW Camera
## 1. Scope
- Single screen, **no tabs**, **no ads**, **no subscriptions**  
- Output **only DNG**, 25 MB/shot  
- iOS 16+, iPhone only

## 2. Core Features
| # | Feature | Rule / Note |
|---|---|---|
| 1 | **Tap-to-meter & focus** | `focusPointOfInterest` + `exposurePointOfInterest`; re-meter on new tap |
| 2 | **Zoom** | 5 discrete buttons: 0.5×, 1×, 2×, 3×, 5×<br>- Auto-detect optical vs digital<br>- Show 8 pt grey label “Digital” for 2 s when digital |
| 3 | **Grid** | 3×3 lines, **off by default**, toggle via **double-tap** |
| 4 | **Torch** | Lightning icon, on/off only, no intensity slider |
| 5 | **Front / back switch** | Flip icon, top-left corner |

## 3. Zoom Logic
```swift
let avail = [0.5, 1.0] + (hasTele ? [2.0, 3.0] : [])
let maxDigital = device.activeFormat.videoZoomFactorUpscaleThreshold
if factor > avail.max() {
    useMainLensWithDigitalCrop(factor, maxDigital) // show "Digital"
}
```

## 4. 已解决的关键技术问题

### 4.1 预览黑屏问题根因分析
**问题现象**: 应用启动时能看到一瞬间画面，然后马上黑屏

**根本原因**:
1. **AVCaptureSession生命周期管理缺陷** - Session在启动后未正确处理中断事件
2. **设备连接状态监控缺失** - 摄像头设备可能在运行过程中断开连接
3. **PreviewLayer连接状态失效** - PreviewLayer的AVCaptureConnection可能在运行过程中变为inactive

**具体技术点**:
- Session中断通知未监听: `.AVCaptureSessionWasInterrupted` / `.AVCaptureSessionInterruptionEnded`
- 应用生命周期事件未处理: `UIApplication.didBecomeActiveNotification` / `UIApplication.willResignActiveNotification`
- 设备连接状态检查机制缺失
- 零尺寸UIView导致的PreviewLayer frame异常

**解决方案实施**:
- ✅ 实现了`preventBlackScreen()`持续监控机制 (CameraModel.swift:219)
- ✅ 添加了`restartSession()`安全重启机制 (CameraModel.swift:246)
- ✅ 在Coordinator中监听应用生命周期事件 (CameraView.swift:285-313)
- ✅ 修复了UIView初始frame为零尺寸的问题 (CameraView.swift:144-145)

### 4.2 日志系统配置
**Log文件路径**: `/var/mobile/Containers/Data/Application/[UUID]/Library/Caches/JustCamLogs/justcam_log.txt`

**获取日志方法**:
1. 通过Xcode Devices窗口导出容器
2. 使用Finder路径: `~/Library/Developer/CoreSimulator/Devices/[设备ID]/data/Containers/Data/Application/[应用ID]/Library/Caches/JustCamLogs/justcam_log.txt`
3. 代码中获取: `CameraLog.getLogFilePath()`

## 5. RAW拍摄功能实现规划

### 5.1 RAW拍摄技术验证清单
**前置条件验证**:
- [ ] 设备支持RAW格式检测
- [ ] RAW像素格式类型确认 (DNG格式)
- [ ] 25MB/张文件大小验证
- [ ] 存储权限申请状态检查

### 5.2 功能实现步骤分解
**阶段1: RAW格式检测与配置** (5个验证点)
**阶段2: 拍摄设置与触发** (3个验证点)  
**阶段3: 文件处理与保存** (4个验证点)
**阶段4: 用户反馈与状态更新** (2个验证点)

### 5.3 测试验证矩阵
- [ ] iPhone 13 mini真实设备测试
- [ ] RAW文件格式验证 (DNG)
- [ ] 文件大小范围确认 (20-30MB)
- [ ] 相册保存验证
- [ ] 连拍限制测试 (RAW禁用连拍)

## 6. Store Compliance
Info.plist: NSCameraUsageDescription, NSPhotoLibraryAddUsageDescription
Store description:
"Shoots only DNG. Digital zoom on devices without optical lens."
