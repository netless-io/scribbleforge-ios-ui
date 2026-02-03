import UIKit
import ScribbleForge

public struct WhiteboardUIState: Equatable {
    public var currentTool: WhiteboardToolType?
    public var strokeColor: UIColor?
    public var fillColor: UIColor?
    public var strokeWidth: Float
    public var fontSize: Float?
    public var dashArray: [Float]?
    public var undoCount: Int
    public var redoCount: Int
    public var pageIndex: Int
    public var pageCount: Int
    public var canDraw: Bool
    public var canNavigate: Bool

    public init(
        currentTool: WhiteboardToolType? = nil,
        strokeColor: UIColor? = nil,
        fillColor: UIColor? = nil,
        strokeWidth: Float = 0,
        fontSize: Float? = nil,
        dashArray: [Float]? = nil,
        undoCount: Int = 0,
        redoCount: Int = 0,
        pageIndex: Int = 0,
        pageCount: Int = 1,
        canDraw: Bool = true,
        canNavigate: Bool = true
    ) {
        self.currentTool = currentTool
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.strokeWidth = strokeWidth
        self.fontSize = fontSize
        self.dashArray = dashArray
        self.undoCount = undoCount
        self.redoCount = redoCount
        self.pageIndex = pageIndex
        self.pageCount = pageCount
        self.canDraw = canDraw
        self.canNavigate = canNavigate
    }
}
