# Develop

## 本地验证

### Swift Package Manager

```bash
swift package dump-package
swift package resolve
```

### Demo 运行

```bash
# CocoaPods Demo
cd Demo && pod install
open Demo/ScribbleForgeSampleUI.xcworkspace

# SwiftPM Demo
open DemoSPM/ScribbleForgeSampleUI-SPM.xcodeproj
```

## 发布到 CocoaPods

```bash
./scripts/release_cocoapods.sh <version>
```

可选参数：
- `--skip-lint`：跳过 `pod spec lint`
- `--dry-run`：只打印要执行的命令

发布前请先确认：
- 已执行 `pod trunk register ...` 并完成邮箱验证
- 当前分支工作区是干净状态（无未提交改动）
- 具备仓库 `origin` 的推送权限
