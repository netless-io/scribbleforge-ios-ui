import CoreGraphics
import ScribbleForge
import UIKit

public struct WhiteboardUIConfig {
    private static let defaultBackgroundColorOptions: [UIColor] = [
        .white,
        UIColor.black.withAlphaComponent(0.8),
        UIColor(sfHex: "#5A7D75") ?? UIColor(red: 90.0 / 255.0, green: 125.0 / 255.0, blue: 117.0 / 255.0, alpha: 1.0)
    ]

    public let showToolbar: Bool
    public let allowedTools: [WhiteboardToolType]
    public let theme: ScribbleForgeUISkin
    public let whiteboardAppId: String
    public let initialBackgroundColor: UIColor
    public let backgroundColorOptions: [UIColor]
    /// Set this to the same width/height ratio used when launching the whiteboard.
    public let whiteboardAspectRatio: CGFloat
    public let launch: (_ room: Room, _ appId: String) -> Void
    public var onJoinResult: ((Result<Void, Error>) -> Void)?

    public init(
        whiteboardAspectRatio: CGFloat = 1920.0 / 1080.0,
        initialBackgroundColor: UIColor = .white,
        backgroundColorOptions: [UIColor] = [],
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
        let normalizedOptions = backgroundColorOptions.isEmpty ? Self.defaultBackgroundColorOptions : backgroundColorOptions
        if normalizedOptions.contains(where: { $0.isEqual(initialBackgroundColor) }) {
            self.backgroundColorOptions = normalizedOptions
        } else {
            self.backgroundColorOptions = [initialBackgroundColor] + normalizedOptions
        }
        self.initialBackgroundColor = initialBackgroundColor
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
