# ScribbleForgeUI

用于将 ScribbleForge 白板与工具栏快速集成到业务 App 的 UIKit UI 组件库。

## 安装

### CocoaPods

添加 ScribbleForgeUI 即可：

```ruby
pod 'ScribbleForgeUI', :git => 'https://github.com/netless-io/scribbleforge-ios-ui.git'
```

## UIKit 使用

`Sources/ScribbleForgeUI/Components/WhiteboardContainerViewController.swift` 已封装好白板 + 工具栏 UI。接入时只需要把它作为子控制器挂到你的页面，并在拿到 `Room` 后启动：

```swift
import UIKit
import ScribbleForge
import ScribbleForgeUI

final class ViewController: UIViewController {
    private let whiteboardContainer = WhiteboardContainerViewController()
    private var room: Room?

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(whiteboardContainer)
        view.addSubview(whiteboardContainer.view)
        // Layout 说明：请在此根据你的页面结构设置 translatesAutoresizingMaskIntoConstraints 和 NSLayoutConstraint。
        whiteboardContainer.didMove(toParent: self)
    }

    private func startWhiteboard(with room: Room) {
        self.room = room
        whiteboardContainer.start(with: room, autoJoin: true)
    }

    deinit {
        whiteboardContainer.stop()
    }
}
```

## Demo 配置

运行 Demo 前，请先在 `Demo/ScribbleForgeSampleUI` 下创建并修改 `RoomConfig.plist`（并确保加入 `ScribbleForgeSampleUI` target）：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ScribbleForgeRoomId</key>
    <string>your-room-id</string>
    <key>ScribbleForgeRoomToken</key>
    <string>your-room-token</string>
    <key>ScribbleForgeUserId</key>
    <string>your-user-id</string>
    <key>ScribbleForgeRtmAppId</key>
    <string>your-rtm-app-id</string>
    <key>ScribbleForgeRtmToken</key>
    <string>your-rtm-token</string>
    <key>ScribbleForgeRegionEndpoint</key>
    <string></string>
    <key>ScribbleForgeWritable</key>
    <true/>
</dict>
</plist>
```

其中 `ScribbleForgeRegionEndpoint` 和 `ScribbleForgeWritable` 为可选项；不填 endpoint 时默认使用 `cn_hz`。

## 许可

内部使用协议。详见 `ScribbleForgeUI.podspec`。
