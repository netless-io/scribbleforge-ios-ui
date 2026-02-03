# ScribbleForgeUI

用于将 ScribbleForge 白板与工具栏快速集成到业务 App 的 UIKit UI 组件库。

## 安装

### CocoaPods

如果你的 Specs 源里没有 ScribbleForge，请直接引用 release 仓库：

```ruby
pod 'ScribbleForge', :git => 'https://github.com/netless-io/scribbleforge-ios-release.git', :tag => '1.1.1'
```

然后添加 ScribbleForgeUI：

```ruby
pod 'ScribbleForgeUI', :git => 'https://github.com/netless-io/scribbleforge-ios-ui.git', :tag => '0.1.0'
```

如果需要指定 ScribbleForge 的子模块（subspec），可以在 Podfile 中显式声明，例如：

```ruby
pod 'ScribbleForge/AgoraRtm2.2.x', :git => 'https://github.com/netless-io/scribbleforge-ios-release.git', :tag => '1.1.1'
pod 'ScribbleForgeUI', :git => 'https://github.com/netless-io/scribbleforge-ios-ui.git', :tag => '0.1.0'
```

### Demo Podfile

示例工程的最小 Podfile 见 `Demo/Podfile`。

## 许可

内部使用协议。详见 `ScribbleForgeUI.podspec`。
