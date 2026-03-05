# Advance

面向需要做二次开发的开发者。  

## 1. 定制建议

### 1.1 功能开关

- 权限变化使用 `setWritable(_:)`，不要只禁用按钮外观。

### 1.2 主题与图标体系

- 优先新建一个完整 `ScribbleForgeUISkin`，避免在业务代码中散落硬编码颜色。
- 使用 `iconProvider` / `actionIconProvider` 统一图标注入，保证 SPM 和 CocoaPods 资源行为一致。
- 深色模式建议使用动态色（`UIColor { trait in ... }`），避免对比度问题。

### 1.3 白板初始化策略

- 若要自定义白板尺寸或策略，优先覆盖 `WhiteboardUIConfig.launch`。
- `whiteboardAspectRatio` 需要与服务端/业务画布约定一致，否则会出现视觉比例偏差。

## 2. 调试与排障清单

- 现象：工具栏按钮无效
  - 检查 `canDraw` 是否被置为 `false`。
- 现象：页码不更新
  - 检查 `WhiteboardDelegate` 是否正常绑定（`bind(whiteboard:roomUserId:)`）。
  - 检查是否正确触发了 `indexedNavigation` 的回调链。
- 现象：白板未显示
  - 检查是否调用了 `start(with:autoJoin:)`。
  - 检查 `Room` 是否 join 成功、`launchWhiteboard` 是否返回。