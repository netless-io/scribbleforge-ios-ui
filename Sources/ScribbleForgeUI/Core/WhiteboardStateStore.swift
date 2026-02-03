import Foundation
import ScribbleForge
import UIKit

public final class WhiteboardStateStore: NSObject {
    public private(set) var state: WhiteboardUIState
    public var onChange: ((WhiteboardUIState) -> Void)?

    private weak var whiteboard: Whiteboard?

    public init(
        initialState: WhiteboardUIState = WhiteboardUIState()
    ) {
        self.state = initialState
    }

    public func bind(whiteboard: Whiteboard, roomUserId: String?) {
        self.whiteboard = whiteboard
        _ = roomUserId
        whiteboard.delegate = self
        syncFromWhiteboard(whiteboard)
    }

    public func setWritable(_ writable: Bool) {
        updateState { state in
            state.canDraw = writable
            state.canNavigate = writable
        }
    }

    private func syncFromWhiteboard(_ whiteboard: Whiteboard) {
        let strokeColor = whiteboard.strokeColor().flatMap { UIColor(sfHex: $0) }
        let fillColor = whiteboard.fillColor().flatMap { UIColor(sfHex: $0) }
        let strokeWidth = whiteboard.strokeWidth() ?? 0
        let fontSize = whiteboard.fontSize()
        let tool = whiteboard.currentTool()
        let dash = whiteboard.dashArray()

        updateState { state in
            state.currentTool = tool
            state.strokeColor = strokeColor
            state.fillColor = fillColor
            state.strokeWidth = strokeWidth
            state.fontSize = fontSize
            state.dashArray = dash
        }

        whiteboard.indexedNavigation.currentPageIndex { [weak self] current in
            whiteboard.indexedNavigation.pageCount { [weak self] count in
                self?.updateState { state in
                    state.pageIndex = current
                    state.pageCount = count
                }
            }
        }
    }

    private func updateState(_ block: (inout WhiteboardUIState) -> Void) {
        var next = state
        block(&next)
        if next != state {
            state = next
            DispatchQueue.main.async { [state, onChange] in
                onChange?(state)
            }
        }
    }
}

extension WhiteboardStateStore: WhiteboardDelegate {
    public func whiteboardElementSelected(_: Whiteboard, info _: WhiteboardSelectInfo) {}

    public func whiteboardElementDeselected(_: Whiteboard) {}

    public func whiteboardUndoStackLengthUpdate(_: Whiteboard, undoStackLength: Int) {
        updateState { state in
            state.undoCount = undoStackLength
        }
    }

    public func whiteboardRedoStackLengthUpdate(_: Whiteboard, redoStackLength: Int) {
        updateState { state in
            state.redoCount = redoStackLength
        }
    }

    public func whiteboardToolInfoUpdate(_: Whiteboard, toolInfo: WhiteboardToolInfo) {
        updateState { state in
            state.currentTool = toolInfo.tool
            state.strokeColor = UIColor(sfHex: toolInfo.strokeColor)
            state.fillColor = toolInfo.fillColor.flatMap { UIColor(sfHex: $0) }
            state.strokeWidth = toolInfo.strokeWidth
            state.fontSize = toolInfo.fontSize
            state.dashArray = toolInfo.dashArray
        }
    }

    public func whiteboardPageInfoUpdate(_: Whiteboard, activePageIndex: Int, pageCount: Int) {
        updateState { state in
            state.pageIndex = activePageIndex
            state.pageCount = pageCount
        }
    }

    public func whiteboardPagePermissionUpdate(_: Whiteboard, userId: String, permission: WhiteboardPermission) {
        _ = userId
        _ = permission
    }

    public func whiteboardError(_: Whiteboard, errorCode: Int, errorMessage: String) {
        print("[ScribbleForgeUI] whiteboard error: \(errorCode) \(errorMessage)")
    }
}
