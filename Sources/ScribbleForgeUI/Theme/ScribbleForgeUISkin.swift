import UIKit
import ScribbleForge

public struct ScribbleForgeUISkin {
    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        }
    }

    public struct Palette {
        public var yellow: UIColor
        public var blue: UIColor
        public var purple: UIColor
        public var red: UIColor
        public var green: UIColor

        public init(yellow: UIColor, blue: UIColor, purple: UIColor, red: UIColor, green: UIColor) {
            self.yellow = yellow
            self.blue = blue
            self.purple = purple
            self.red = red
            self.green = green
        }

        public static let `default` = Palette(
            yellow: UIColor(sfHex: "#F5C542")!,
            blue: UIColor(sfHex: "#4A74FF")!,
            purple: UIColor(sfHex: "#7A4CE3")!,
            red: UIColor(sfHex: "#FF4D4F")!,
            green: UIColor(sfHex: "#9AC46B")!
        )
    }

    public struct Colors {
        public var toolbarBorder: UIColor
        public var toolbarSelectionBorder: UIColor
        public var toolbarItemBackground: UIColor
        public var toolbarSelectionFill: UIColor
        public var backgroundSelectionBorder: UIColor
        public var popupBackground: UIColor
        public var popupContentBackground: UIColor
        public var popupBorder: UIColor
        public var popupShadow: UIColor
        public var widthRing: UIColor
        public var widthDot: UIColor
        public var palette: Palette

        public init(
            toolbarBorder: UIColor,
            toolbarSelectionBorder: UIColor,
            toolbarItemBackground: UIColor,
            toolbarSelectionFill: UIColor,
            backgroundSelectionBorder: UIColor,
            popupBackground: UIColor,
            popupContentBackground: UIColor,
            popupBorder: UIColor,
            popupShadow: UIColor,
            widthRing: UIColor,
            widthDot: UIColor,
            palette: Palette
        ) {
            self.toolbarBorder = toolbarBorder
            self.toolbarSelectionBorder = toolbarSelectionBorder
            self.toolbarItemBackground = toolbarItemBackground
            self.toolbarSelectionFill = toolbarSelectionFill
            self.backgroundSelectionBorder = backgroundSelectionBorder
            self.popupBackground = popupBackground
            self.popupContentBackground = popupContentBackground
            self.popupBorder = popupBorder
            self.popupShadow = popupShadow
            self.widthRing = widthRing
            self.widthDot = widthDot
            self.palette = palette
        }

        public static let `default` = Colors(
            toolbarBorder: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#E3E7EF")!,
                dark: UIColor(sfHex: "#4A4C5F80")!
            ),
            toolbarSelectionBorder: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#4262FF")!,
                dark: UIColor(sfHex: "#506EFF")!
            ),
            toolbarItemBackground: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#F1F3F8")!,
                dark: UIColor(sfHex: "#353638F2")!
            ),
            toolbarSelectionFill: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#4262FF1A")!,
                dark: UIColor(sfHex: "#8EA1FF33")!
            ),
            backgroundSelectionBorder: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#506EFF")!,
                dark: UIColor(sfHex: "#506EFF")!
            ),
            popupBackground: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#FFFFFFF2")!,
                dark: UIColor(sfHex: "#292E33F2")!
            ),
            popupContentBackground: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#FFFFFF")!,
                dark: .init(sfHex: "#292E33F2")!
            ),
            popupBorder: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#D8D8D880")!,
                dark: UIColor(sfHex: "#40404033")!
            ),
            popupShadow: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#97979733")!,
                dark: .clear
            ),
            widthRing: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#3D3D3D")!,
                dark: .white
            ),
            widthDot: ScribbleForgeUISkin.dynamic(
                light: UIColor(sfHex: "#3E4271")!,
                dark: UIColor(sfHex: "#FFFFFFE5")!
            ),
            palette: .default
        )
    }

    public typealias IconProvider = (_ tool: WhiteboardToolType) -> UIImage?
    public typealias ActionIconProvider = (_ action: WhiteboardToolbarAction) -> UIImage?
    public typealias BackgroundViewProvider = () -> UIView

    public var id: String
    public var toolbarBackgroundColor: UIColor
    public var toolbarTintColor: UIColor
    public var toolbarSelectedTintColor: UIColor
    public var toolbarDisabledTintColor: UIColor
    public var pageTextColor: UIColor
    public var colors: Colors
    public var iconProvider: IconProvider?
    public var actionIconProvider: ActionIconProvider?
    public var toolbarBackgroundViewProvider: BackgroundViewProvider?

    public init(
        id: String,
        toolbarBackgroundColor: UIColor,
        toolbarTintColor: UIColor,
        toolbarSelectedTintColor: UIColor,
        toolbarDisabledTintColor: UIColor,
        pageTextColor: UIColor,
        colors: Colors = .default,
        iconProvider: IconProvider? = nil,
        actionIconProvider: ActionIconProvider? = nil,
        toolbarBackgroundViewProvider: BackgroundViewProvider? = nil
    ) {
        self.id = id
        self.toolbarBackgroundColor = toolbarBackgroundColor
        self.toolbarTintColor = toolbarTintColor
        self.toolbarSelectedTintColor = toolbarSelectedTintColor
        self.toolbarDisabledTintColor = toolbarDisabledTintColor
        self.pageTextColor = pageTextColor
        self.colors = colors
        self.iconProvider = iconProvider
        self.actionIconProvider = actionIconProvider
        self.toolbarBackgroundViewProvider = toolbarBackgroundViewProvider
    }

    public static let specA = ScribbleForgeUISkin(
        id: "specA",
        toolbarBackgroundColor: dynamic(
            light: UIColor(white: 1.0, alpha: 0.92),
            dark: UIColor(white: 0.1, alpha: 0.92)
        ),
        toolbarTintColor: dynamic(
            light: UIColor(white: 0.35, alpha: 1.0),
            dark: UIColor(white: 0.9, alpha: 1.0)
        ),
        toolbarSelectedTintColor: dynamic(
            light: UIColor.systemBlue,
            dark: UIColor.systemBlue
        ),
        toolbarDisabledTintColor: dynamic(
            light: UIColor(white: 0.6, alpha: 0.6),
            dark: UIColor(white: 0.6, alpha: 0.5)
        ),
        pageTextColor: dynamic(
            light: UIColor(white: 0.1, alpha: 0.9),
            dark: UIColor(white: 0.95, alpha: 0.9)
        )
    )

    public static let aPaaS = ScribbleForgeUISkin(
        id: "aPaaS",
        toolbarBackgroundColor: dynamic(
            light: .white.withAlphaComponent(0.85),
            dark: UIColor(sfHex: "#2F2F2FA6")!
        ),
        toolbarTintColor: dynamic(
            light: UIColor(sfHex: "#373C42")!,
            dark: UIColor(white: 0.95, alpha: 0.95)
        ),
        toolbarSelectedTintColor: dynamic(
            light: UIColor(sfHex: "#373C42")!,
            dark: UIColor.white
        ),
        toolbarDisabledTintColor: dynamic(
            light: UIColor(white: 1.0, alpha: 0.35),
            dark: UIColor(white: 0.7, alpha: 0.4)
        ),
        pageTextColor: dynamic(
            light: UIColor.white,
            dark: UIColor(white: 0.95, alpha: 0.9)
        ),
        iconProvider: { tool in
            let name: String?
            switch tool {
            case .curve:
                name = "fcr_whiteboard_pen1"
            case .text:
                name = "fcr_mobile_whiteboard_text"
            case .eraser:
                name = "fcr_mobile_whiteboard_eraser"
            case .rectangle:
                name = "fcr_whiteboard_shap_square"
            case .ellipse:
                name = "fcr_whiteboard_shap_circle"
            case .triangle:
                name = "fcr_whiteboard_shap_triangle"
            case .line:
                name = "fcr_whiteboard_shap_line"
            case .arrow:
                name = "fcr_whiteboard_shap_arrow"
            case .selector:
                name = "fcr_whiteboard_whitechoose"
            case .laser:
                name = "fcr_spotlinght"
            default:
                name = nil
            }
            guard let name else { return nil }
            let image = ScribbleForgeUIResources.image(named: name)
            if tool == .laser {
                return image?.withRenderingMode(.alwaysOriginal)
            }
            return image?.withRenderingMode(.alwaysTemplate)
        },
        actionIconProvider: { action in
            switch action {
            case .undo:
                return ScribbleForgeUIResources.image(named: "fcr_mobile_whiteboard_revoke")?.withRenderingMode(.alwaysTemplate)
            case .redo:
                return ScribbleForgeUIResources.image(named: "fcr_mobile_whiteboardedit")?.withRenderingMode(.alwaysTemplate)
            case .colorSettings:
                return ScribbleForgeUIResources.image(named: "fcr_whiteboard_colorshape")?.withRenderingMode(.alwaysTemplate)
            case .shapePicker:
                return ScribbleForgeUIResources.image(named: "fcr_whiteboard_shap_square")?.withRenderingMode(.alwaysTemplate)
            case .save:
                return ScribbleForgeUIResources.image(named: "fcr_download")?.withRenderingMode(.alwaysTemplate)
            case .backgroundColor:
                return ScribbleForgeUIResources.image(named: "fcr_whiteboard_bg")?.withRenderingMode(.alwaysTemplate)
            case .prevPage, .nextPage:
                return nil
            }
        },
        toolbarBackgroundViewProvider: {
            return UIView()
        }
    )

    public static let specB = ScribbleForgeUISkin(
        id: "specB",
        toolbarBackgroundColor: UIColor(white: 0.12, alpha: 0.9),
        toolbarTintColor: UIColor(white: 0.9, alpha: 0.85),
        toolbarSelectedTintColor: UIColor.systemGreen,
        toolbarDisabledTintColor: UIColor(white: 0.7, alpha: 0.4),
        pageTextColor: UIColor(white: 0.95, alpha: 0.9)
    )

    public static let appas = ScribbleForgeUISkin.aPaaS

    public static let `default` = ScribbleForgeUISkin.aPaaS
}
