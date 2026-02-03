import CoreGraphics
import ScribbleForge

public struct WhiteboardUIConfig {
    public let showToolbar: Bool
    public let allowedTools: [WhiteboardToolType]
    public let theme: ScribbleForgeUISkin
    public let whiteboardAppId: String
    /// Set this to the same width/height ratio used when launching the whiteboard.
    public let whiteboardAspectRatio: CGFloat
    public let launch: (_ room: Room, _ appId: String) -> Void
    public var onJoinResult: ((Result<Void, Error>) -> Void)?

    public init(
        whiteboardAspectRatio: CGFloat = 1920.0 / 1080.0,
        onJoinResult: ((Result<Void, Error>) -> Void)? = nil
    ) {
        self.showToolbar = true
        self.allowedTools = [
            .selector,
            .curve,
            .rectangle,
            .triangle,
            .ellipse,
            .arrow,
            .line,
            .text,
            .eraser
        ]
        self.theme = .default
        self.whiteboardAppId = "MainWhiteboard"
        let safeAspectRatio = max(whiteboardAspectRatio, 0.01)
        self.whiteboardAspectRatio = safeAspectRatio
        self.launch = { room, appId in
            let height = 1080
            let width = max(Int((CGFloat(height) * safeAspectRatio).rounded()), 1)
            room.launchWhiteboard(
                appId: appId,
                option: .init(width: width, height: height, maxScaleRatio: -1)
            ) { _ in }
        }
        self.onJoinResult = onJoinResult
    }
}
