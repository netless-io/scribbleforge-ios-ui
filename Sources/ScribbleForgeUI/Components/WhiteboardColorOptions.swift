import UIKit

struct WhiteboardColorOption: Equatable {
    let id: String
    let color: UIColor
}

enum WhiteboardColorPalette {
    static func options(using palette: ScribbleForgeUISkin.Palette) -> [WhiteboardColorOption] {
        return [
            .init(id: "yellow", color: palette.yellow),
            .init(id: "blue", color: palette.blue),
            .init(id: "purple", color: palette.purple),
            .init(id: "red", color: palette.red),
            .init(id: "green", color: palette.green)
        ]
    }
}
