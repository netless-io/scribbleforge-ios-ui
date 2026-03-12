import UIKit
import ScribbleForge

public final class WhiteboardToolbarView: UIView {
    public var onToolSelected: ((WhiteboardToolType) -> Void)?
    public var onUndo: (() -> Void)?
    public var onRedo: (() -> Void)?
    public var onPrevPage: (() -> Void)?
    public var onNextPage: (() -> Void)?
    public var onColorSettings: (() -> Void)?
    public var onShapePicker: (() -> Void)?
    public var onSave: (() -> Void)?
    public var onBackgroundColor: (() -> Void)?
    public var onCollapsedStateChanged: ((Bool) -> Void)?
    public var isCollapsedState: Bool { isCollapsed }

    private enum ToolbarItem: Hashable {
        case tool(WhiteboardToolType)
        case action(WhiteboardToolbarAction)
    }

    private let containerStack = UIStackView()
    private let rightControlsStack = UIStackView()
    private let itemScrollView = UIScrollView()
    private let itemStack = UIStackView()
    private let leadingSeparatorView = UIView()
    private let trailingSeparatorView = UIView()
    private var toolButtons: [WhiteboardToolType: UIButton] = [:]
    private var actionButtons: [WhiteboardToolbarAction: UIButton] = [:]
    private var toolbarItems: [ToolbarItem] = []
    private var allowedTools: [WhiteboardToolType] = []
    private static let toolbarToolOrder: [WhiteboardToolType] = [
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
    private static let shapeTools: [WhiteboardToolType] = [
        .rectangle,
        .triangle,
        .ellipse,
        .arrow,
        .line
    ]
    private static let toolbarItemOrder: [ToolbarItem] = [
        .tool(.selector),
        .tool(.curve),
        .action(.shapePicker),
        .action(.colorSettings),
        .tool(.text),
        .tool(.eraser),
        .action(.save),
        .action(.backgroundColor)
    ]
    private var theme: ScribbleForgeUISkin = .default
    private var backgroundView: UIView?
    private var lastState: WhiteboardUIState?
    private var lastShapeTool: WhiteboardToolType?

    private let undoButton = UIButton(type: .system)
    private let redoButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private var isCollapsed = false
    private var isFullWidthStyle: Bool?
    private var layoutAxis: NSLayoutConstraint.Axis = .horizontal
    private var itemScrollSizeConstraint: NSLayoutConstraint?
    private var itemStackCrossConstraint: NSLayoutConstraint?
    private var toolbarThicknessConstraint: NSLayoutConstraint?
    private var containerLeadingConstraint: NSLayoutConstraint?
    private var containerTrailingConstraint: NSLayoutConstraint?
    private var containerTopConstraint: NSLayoutConstraint?
    private var containerBottomConstraint: NSLayoutConstraint?
    private var leadingSeparatorWidthConstraint: NSLayoutConstraint?
    private var leadingSeparatorHeightConstraint: NSLayoutConstraint?
    private var trailingSeparatorWidthConstraint: NSLayoutConstraint?
    private var trailingSeparatorHeightConstraint: NSLayoutConstraint?
    private static let horizontalContentInset: CGFloat = 14
    private static let itemSpacing: CGFloat = 20

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public func configure(allowedTools: [WhiteboardToolType], theme: ScribbleForgeUISkin) {
        let requested = Set(allowedTools)
        let filtered = Self.toolbarToolOrder.filter { requested.contains($0) }
        self.allowedTools = filtered.isEmpty ? Self.toolbarToolOrder : filtered
        self.theme = theme
        rebuildItems()
        applyTheme()
    }

    public func setCollapsedState(_ collapsed: Bool) {
        setCollapsed(collapsed)
    }

    public func setLayoutAxis(_ axis: NSLayoutConstraint.Axis) {
        guard layoutAxis != axis else { return }
        layoutAxis = axis
        containerStack.axis = axis
        rightControlsStack.axis = axis
        itemStack.axis = axis
        itemScrollView.alwaysBounceHorizontal = axis == .horizontal
        itemScrollView.alwaysBounceVertical = axis == .vertical
        itemScrollView.showsHorizontalScrollIndicator = false
        itemScrollView.showsVerticalScrollIndicator = false
        if axis == .horizontal {
            itemScrollView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            itemScrollView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        } else {
            itemScrollView.setContentHuggingPriority(.defaultLow, for: .vertical)
            itemScrollView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        }

        itemScrollSizeConstraint?.isActive = false
        if axis == .horizontal {
            itemScrollSizeConstraint = itemScrollView.heightAnchor.constraint(equalToConstant: 42)
            containerTopConstraint?.constant = 4
            containerBottomConstraint?.constant = -4
            leadingSeparatorWidthConstraint?.isActive = false
            leadingSeparatorHeightConstraint?.isActive = false
            trailingSeparatorWidthConstraint?.isActive = false
            trailingSeparatorHeightConstraint?.isActive = false
            leadingSeparatorWidthConstraint = leadingSeparatorView.widthAnchor.constraint(equalToConstant: 1)
            leadingSeparatorHeightConstraint = leadingSeparatorView.heightAnchor.constraint(equalToConstant: 26)
            trailingSeparatorWidthConstraint = trailingSeparatorView.widthAnchor.constraint(equalToConstant: 1)
            trailingSeparatorHeightConstraint = trailingSeparatorView.heightAnchor.constraint(equalToConstant: 26)
        } else {
            itemScrollSizeConstraint = itemScrollView.widthAnchor.constraint(equalToConstant: 42)
            containerTopConstraint?.constant = Self.horizontalContentInset
            containerBottomConstraint?.constant = -Self.horizontalContentInset
            leadingSeparatorWidthConstraint?.isActive = false
            leadingSeparatorHeightConstraint?.isActive = false
            trailingSeparatorWidthConstraint?.isActive = false
            trailingSeparatorHeightConstraint?.isActive = false
            leadingSeparatorWidthConstraint = leadingSeparatorView.widthAnchor.constraint(equalToConstant: 26)
            leadingSeparatorHeightConstraint = leadingSeparatorView.heightAnchor.constraint(equalToConstant: 1)
            trailingSeparatorWidthConstraint = trailingSeparatorView.widthAnchor.constraint(equalToConstant: 26)
            trailingSeparatorHeightConstraint = trailingSeparatorView.heightAnchor.constraint(equalToConstant: 1)
        }
        itemScrollSizeConstraint?.isActive = true
        leadingSeparatorWidthConstraint?.isActive = true
        leadingSeparatorHeightConstraint?.isActive = true
        trailingSeparatorWidthConstraint?.isActive = true
        trailingSeparatorHeightConstraint?.isActive = true

        toolbarThicknessConstraint?.isActive = false
        if axis == .horizontal {
            toolbarThicknessConstraint = heightAnchor.constraint(equalToConstant: 70)
        } else {
            toolbarThicknessConstraint = widthAnchor.constraint(equalToConstant: 70)
        }
        toolbarThicknessConstraint?.isActive = true

        itemStackCrossConstraint?.isActive = false
        if axis == .horizontal {
            itemStackCrossConstraint = itemStack.heightAnchor.constraint(equalTo: itemScrollView.frameLayoutGuide.heightAnchor)
        } else {
            itemStackCrossConstraint = itemStack.widthAnchor.constraint(equalTo: itemScrollView.frameLayoutGuide.widthAnchor)
        }
        itemStackCrossConstraint?.isActive = true

        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    public func toolButtonFrame(for tool: WhiteboardToolType, in view: UIView) -> CGRect? {
        guard let button = toolButtons[tool] else { return nil }
        return button.convert(button.bounds, to: view)
    }

    public func actionButtonFrame(for action: WhiteboardToolbarAction, in view: UIView) -> CGRect? {
        guard let button = actionButtons[action] else { return nil }
        return button.convert(button.bounds, to: view)
    }

    public func apply(state: WhiteboardUIState) {
        lastState = state
        let normalTint = theme.toolbarTintColor
        let selectedTint = theme.toolbarSelectedTintColor
        let disabledTint = theme.toolbarDisabledTintColor
        for (tool, button) in toolButtons {
            let enabled = state.canDraw
            if !enabled {
                button.tintColor = disabledTint
                button.backgroundColor = theme.colors.toolbarItemBackground
                button.layer.borderWidth = 0
            } else if tool == state.currentTool {
                button.tintColor = selectedTint
                button.backgroundColor = theme.colors.toolbarItemBackground
                button.layer.borderWidth = 4
                button.layer.borderColor = theme.colors.toolbarSelectionBorder.resolvedColor(with: traitCollection).cgColor
            } else {
                button.tintColor = normalTint
                button.backgroundColor = theme.colors.toolbarItemBackground
                button.layer.borderWidth = 0
            }
            button.isEnabled = enabled
            button.alpha = enabled ? 1.0 : 0.4
        }
        for (action, button) in actionButtons {
            let enabled = state.canDraw
            button.isEnabled = enabled
            button.alpha = enabled ? 1.0 : 0.4
            button.tintColor = enabled ? normalTint : disabledTint
            button.backgroundColor = theme.colors.toolbarItemBackground
            button.layer.borderWidth = 0
            if action == .shapePicker {
                button.layer.borderColor = theme.colors.toolbarSelectionBorder.resolvedColor(with: traitCollection).cgColor
            }
        }
        let undoEnabled = state.canDraw && state.undoCount > 0
        undoButton.isEnabled = undoEnabled
        undoButton.alpha = undoEnabled ? 1.0 : 0.4
        undoButton.tintColor = undoEnabled ? normalTint : disabledTint
        undoButton.backgroundColor = theme.colors.toolbarItemBackground
        undoButton.layer.borderWidth = 0

        let redoEnabled = state.canDraw && state.redoCount > 0
        redoButton.isEnabled = redoEnabled
        redoButton.alpha = redoEnabled ? 1.0 : 0.4
        redoButton.tintColor = redoEnabled ? normalTint : disabledTint
        redoButton.backgroundColor = theme.colors.toolbarItemBackground
        redoButton.layer.borderWidth = 0

        closeButton.tintColor = normalTint
        updateShapePickerSelection(for: state.currentTool, enabled: state.canDraw)
        updateColorSettingsIcon(color: state.strokeColor ?? normalTint)
    }

    private func setupView() {
        layer.cornerRadius = 0
        layer.masksToBounds = true

        containerStack.axis = .horizontal
        containerStack.spacing = Self.itemSpacing
        containerStack.alignment = .center
        containerStack.distribution = .fill
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        rightControlsStack.axis = .horizontal
        rightControlsStack.spacing = Self.itemSpacing
        rightControlsStack.alignment = .center
        rightControlsStack.distribution = .fill
        rightControlsStack.translatesAutoresizingMaskIntoConstraints = false

        itemScrollView.translatesAutoresizingMaskIntoConstraints = false
        itemScrollView.showsHorizontalScrollIndicator = false
        itemScrollView.showsVerticalScrollIndicator = false
        itemScrollView.alwaysBounceHorizontal = true
        itemScrollView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        itemScrollView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        itemScrollSizeConstraint = itemScrollView.heightAnchor.constraint(equalToConstant: 42)
        itemScrollSizeConstraint?.isActive = true

        itemStack.axis = .horizontal
        itemStack.spacing = Self.itemSpacing
        itemStack.alignment = .center
        itemStack.translatesAutoresizingMaskIntoConstraints = false

        leadingSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        trailingSeparatorView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerStack)
        containerStack.addArrangedSubview(itemScrollView)
        containerStack.addArrangedSubview(rightControlsStack)

        rightControlsStack.addArrangedSubview(leadingSeparatorView)
        rightControlsStack.addArrangedSubview(undoButton)
        rightControlsStack.addArrangedSubview(redoButton)
        rightControlsStack.addArrangedSubview(trailingSeparatorView)
        rightControlsStack.addArrangedSubview(closeButton)

        itemScrollView.addSubview(itemStack)

        itemStackCrossConstraint = itemStack.heightAnchor.constraint(equalTo: itemScrollView.frameLayoutGuide.heightAnchor)
        containerLeadingConstraint = containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.horizontalContentInset)
        containerTrailingConstraint = containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.horizontalContentInset)
        containerTopConstraint = containerStack.topAnchor.constraint(equalTo: topAnchor, constant: 4)
        containerBottomConstraint = containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        NSLayoutConstraint.activate([
            containerLeadingConstraint!,
            containerTrailingConstraint!,
            containerTopConstraint!,
            containerBottomConstraint!,
            itemStack.leadingAnchor.constraint(equalTo: itemScrollView.contentLayoutGuide.leadingAnchor),
            itemStack.trailingAnchor.constraint(equalTo: itemScrollView.contentLayoutGuide.trailingAnchor),
            itemStack.topAnchor.constraint(equalTo: itemScrollView.contentLayoutGuide.topAnchor),
            itemStack.bottomAnchor.constraint(equalTo: itemScrollView.contentLayoutGuide.bottomAnchor),
            itemStackCrossConstraint!
        ])
        toolbarThicknessConstraint = heightAnchor.constraint(equalToConstant: 70)
        toolbarThicknessConstraint?.isActive = true
        leadingSeparatorWidthConstraint = leadingSeparatorView.widthAnchor.constraint(equalToConstant: 1)
        leadingSeparatorHeightConstraint = leadingSeparatorView.heightAnchor.constraint(equalToConstant: 26)
        trailingSeparatorWidthConstraint = trailingSeparatorView.widthAnchor.constraint(equalToConstant: 1)
        trailingSeparatorHeightConstraint = trailingSeparatorView.heightAnchor.constraint(equalToConstant: 26)
        leadingSeparatorWidthConstraint?.isActive = true
        leadingSeparatorHeightConstraint?.isActive = true
        trailingSeparatorWidthConstraint?.isActive = true
        trailingSeparatorHeightConstraint?.isActive = true

        setupActionButtons()
        applyTheme()
    }

    private func setupActionButtons() {
        configureActionButton(undoButton, action: .undo, selector: #selector(undoTapped))
        configureActionButton(redoButton, action: .redo, selector: #selector(redoTapped))
        configureResourceButton(closeButton, imageName: "fcr_fold", templated: true, selector: #selector(closeTapped))
    }

    private func rebuildItems() {
        itemStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        toolButtons.removeAll()
        actionButtons.removeAll()

        let allowedSet = Set(allowedTools)
        let allowedShapes = Self.shapeTools.filter { allowedSet.contains($0) }
        toolbarItems = Self.toolbarItemOrder.filter { item in
            switch item {
            case .tool(let tool):
                return allowedSet.contains(tool)
            case .action(let action):
                if action == .shapePicker {
                    return !allowedShapes.isEmpty
                }
                return true
            }
        }

        for (index, item) in toolbarItems.enumerated() {
            let button = UIButton(type: .system)
            var needsTarget = true
            switch item {
            case .tool(let tool):
                if let image = theme.iconProvider?(tool) {
                    button.setImage(image, for: .normal)
                    applyButtonLayout(button)
                } else {
                    configureButton(button, systemName: systemImageName(for: tool), action: #selector(itemTapped(_:)))
                    needsTarget = false
                }
                button.accessibilityLabel = String(describing: tool)
                toolButtons[tool] = button
            case .action(let action):
                configureActionButton(button, action: action, selector: #selector(itemTapped(_:)))
                needsTarget = false
                button.accessibilityLabel = String(describing: action)
                actionButtons[action] = button
            }
            button.tag = index
            if needsTarget {
                button.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            }
            itemStack.addArrangedSubview(button)
        }
        invalidateIntrinsicContentSize()
    }

    private func applyTheme() {
        backgroundColor = theme.toolbarBackgroundColor
        layer.borderColor = nil
        layer.borderWidth = 0
        if let provider = theme.toolbarBackgroundViewProvider {
            let view = provider()
            view.translatesAutoresizingMaskIntoConstraints = false
            backgroundView?.removeFromSuperview()
            backgroundView = view
            addSubview(view)
            sendSubviewToBack(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: leadingAnchor),
                view.trailingAnchor.constraint(equalTo: trailingAnchor),
                view.topAnchor.constraint(equalTo: topAnchor),
                view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        } else {
            backgroundView?.removeFromSuperview()
            backgroundView = nil
        }
        updateActionIcons()
        setActionImage(.undo, on: undoButton)
        setActionImage(.redo, on: redoButton)
        let normalTint = theme.toolbarTintColor
        actionButtons.values.forEach { $0.tintColor = normalTint }
        undoButton.tintColor = normalTint
        redoButton.tintColor = normalTint
        closeButton.tintColor = normalTint
        leadingSeparatorView.backgroundColor = theme.colors.toolbarBorder
        trailingSeparatorView.backgroundColor = theme.colors.toolbarBorder
        updateShapePickerIcon(for: lastState?.currentTool)
        updateColorSettingsIcon(color: lastState?.strokeColor ?? normalTint)
    }

    private func configureButton(_ button: UIButton, systemName: String, action: Selector) {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let image = UIImage(systemName: systemName, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        applyButtonLayout(button)
    }

    private func configureActionButton(_ button: UIButton, action: WhiteboardToolbarAction, selector: Selector) {
        setActionImage(action, on: button)
        button.addTarget(self, action: selector, for: .touchUpInside)
        applyButtonLayout(button)
    }

    private func configureResourceButton(_ button: UIButton, imageName: String, templated: Bool, selector: Selector) {
        let image = ScribbleForgeUIResources.image(named: imageName)
        if templated {
            button.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            button.setImage(image?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        button.addTarget(self, action: selector, for: .touchUpInside)
        applyButtonLayout(button)
    }

    private func updateActionIcons() {
        for (action, button) in actionButtons {
            setActionImage(action, on: button)
        }
    }

    private func updateColorSettingsIcon(color: UIColor) {
        guard let button = actionButtons[.colorSettings],
              let base = ScribbleForgeUIResources.image(named: "fcr_whiteboard_colorshape")
        else { return }
        let format = UIGraphicsImageRendererFormat()
        format.scale = base.scale
        let renderer = UIGraphicsImageRenderer(size: base.size, format: format)
        let image = renderer.image { ctx in
            base.draw(in: CGRect(origin: .zero, size: base.size))
            let dotSize: CGFloat = 4
            let dotRect = CGRect(
                x: (base.size.width - dotSize) / 2,
                y: (base.size.height - dotSize) / 2,
                width: dotSize,
                height: dotSize
            )
            let resolvedColor = color.resolvedColor(with: traitCollection)
            ctx.cgContext.setFillColor(resolvedColor.cgColor)
            ctx.cgContext.fillEllipse(in: dotRect)
        }
        button.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    private func updateShapePickerSelection(for currentTool: WhiteboardToolType?, enabled: Bool) {
        guard let button = actionButtons[.shapePicker] else { return }
        if let tool = currentTool, Self.shapeTools.contains(tool) {
            lastShapeTool = tool
        }
        let isShapeSelected = currentTool.map { Self.shapeTools.contains($0) } ?? false
        if enabled && isShapeSelected {
            button.layer.borderWidth = 4
            button.backgroundColor = theme.colors.toolbarItemBackground
        } else {
            button.layer.borderWidth = 0
            button.backgroundColor = theme.colors.toolbarItemBackground
        }
        updateShapePickerIcon(for: currentTool)
    }

    private func updateShapePickerIcon(for tool: WhiteboardToolType?) {
        guard let button = actionButtons[.shapePicker] else { return }
        let shapeTool = tool.flatMap { Self.shapeTools.contains($0) ? $0 : nil }
            ?? lastShapeTool
            ?? defaultShapeTool
        guard let shapeTool else { return }
        if let image = toolImage(for: shapeTool) {
            button.setImage(image, for: .normal)
        }
    }

    private var defaultShapeTool: WhiteboardToolType? {
        return Self.shapeTools.first { allowedTools.contains($0) }
    }

    private func toolImage(for tool: WhiteboardToolType) -> UIImage? {
        if let image = theme.iconProvider?(tool) {
            return image
        }
        if let name = resourceName(for: tool) {
            let image = ScribbleForgeUIResources.image(named: name)
            if tool == .laser {
                return image?.withRenderingMode(.alwaysOriginal)
            }
            return image?.withRenderingMode(.alwaysTemplate)
        }
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        return UIImage(systemName: systemImageName(for: tool), withConfiguration: config)
    }

    private func resourceName(for tool: WhiteboardToolType) -> String? {
        switch tool {
        case .curve:
            return "fcr_whiteboard_pen1"
        case .text:
            return "fcr_mobile_whiteboard_text"
        case .eraser:
            return "fcr_mobile_whiteboard_eraser"
        case .rectangle:
            return "fcr_whiteboard_shap_square"
        case .ellipse:
            return "fcr_whiteboard_shap_circle"
        case .triangle:
            return "fcr_whiteboard_shap_triangle"
        case .line:
            return "fcr_whiteboard_shap_line"
        case .arrow:
            return "fcr_whiteboard_shap_arrow"
        case .selector:
            return "fcr_whiteboard_whitechoose"
        case .laser:
            return "fcr_spotlinght"
        case .grab, .pointer:
            return nil
        }
    }

    private func setActionImage(_ action: WhiteboardToolbarAction, on button: UIButton) {
        if action == .colorSettings {
            let image = ScribbleForgeUIResources.image(named: "fcr_whiteboard_colorshape")
            button.setImage(image?.withRenderingMode(.alwaysOriginal), for: .normal)
            return
        }
        if let image = theme.actionIconProvider?(action) {
            button.setImage(image, for: .normal)
            return
        }
        if let name = actionResourceName(for: action) {
            let image = ScribbleForgeUIResources.image(named: name)
            button.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
            return
        }
        if let systemName = systemImageName(for: action) {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
            let image = UIImage(systemName: systemName, withConfiguration: config)
            button.setImage(image, for: .normal)
        }
    }

    private func actionResourceName(for action: WhiteboardToolbarAction) -> String? {
        switch action {
        case .undo:
            return "fcr_mobile_whiteboard_undo"
        case .redo:
            return "fcr_mobile_whiteboard_redo"
        case .colorSettings:
            return "fcr_whiteboard_colorshape"
        case .shapePicker:
            return "fcr_whiteboard_shap_square"
        case .save:
            return "fcr_download"
        case .backgroundColor:
            return "fcr_whiteboard_bg"
        case .prevPage, .nextPage:
            return nil
        }
    }

    private func systemImageName(for action: WhiteboardToolbarAction) -> String? {
        switch action {
        case .undo:
            return "arrow.uturn.backward"
        case .redo:
            return "arrow.uturn.forward"
        case .prevPage:
            return "chevron.left"
        case .nextPage:
            return "chevron.right"
        case .colorSettings:
            return "paintpalette"
        case .shapePicker:
            return "square.on.circle"
        case .save:
            return "square.and.arrow.down"
        case .backgroundColor:
            return "paintbrush"
        }
    }

    private func applyButtonLayout(_ button: UIButton) {
        button.widthAnchor.constraint(equalToConstant: 42).isActive = true
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        button.layer.cornerRadius = 21
        button.layer.cornerCurve = .continuous
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        button.imageView?.contentMode = .scaleAspectFit
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
            if let state = lastState {
                apply(state: state)
            }
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerStyleIfNeeded()
    }

    private func setCollapsed(_ collapsed: Bool) {
        guard collapsed != isCollapsed else { return }
        isCollapsed = collapsed
        itemScrollView.isHidden = collapsed
        leadingSeparatorView.isHidden = collapsed
        undoButton.isHidden = collapsed
        redoButton.isHidden = collapsed
        trailingSeparatorView.isHidden = collapsed
        closeButton.isHidden = collapsed
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        onCollapsedStateChanged?(collapsed)
    }

    @objc private func itemTapped(_ sender: UIButton) {
        guard sender.tag >= 0 && sender.tag < toolbarItems.count else { return }
        let item = toolbarItems[sender.tag]
        switch item {
        case .tool(let tool):
            onToolSelected?(tool)
        case .action(let action):
            handleAction(action)
        }
    }

    private func handleAction(_ action: WhiteboardToolbarAction) {
        switch action {
        case .undo:
            onUndo?()
        case .redo:
            onRedo?()
        case .prevPage:
            onPrevPage?()
        case .nextPage:
            onNextPage?()
        case .colorSettings:
            onColorSettings?()
        case .shapePicker:
            onShapePicker?()
        case .save:
            onSave?()
        case .backgroundColor:
            onBackgroundColor?()
        }
    }

    @objc private func closeTapped() {
        setCollapsed(true)
    }

    @objc private func undoTapped() {
        onUndo?()
    }

    @objc private func redoTapped() {
        onRedo?()
    }

    private func systemImageName(for tool: WhiteboardToolType) -> String {
        switch tool {
        case .selector:
            return "lasso"
        case .curve:
            return "scribble.variable"
        case .text:
            return "textformat.alt"
        case .eraser:
            return "eraser.fill"
        case .ellipse:
            return "circle"
        case .laser:
            return "dot.circle.and.hand.point.up.left.fill"
        case .rectangle:
            return "rectangle"
        case .line:
            return "line.diagonal"
        case .triangle:
            return "triangle"
        case .arrow:
            return "arrow.backward"
        case .grab:
            return "hand.draw.fill"
        case .pointer:
            return "cursorarrow.rays"
        @unknown default:
            return ""
        }
    }

    public override var intrinsicContentSize: CGSize {
        let visibleSubviews = containerStack.arrangedSubviews.filter { !$0.isHidden }
        let spacing = CGFloat(max(visibleSubviews.count - 1, 0)) * containerStack.spacing
        if layoutAxis == .vertical {
            let itemHeight = itemStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var height: CGFloat = 0
            var maxWidth: CGFloat = 0
            for view in visibleSubviews {
                if view === itemScrollView {
                    height += itemHeight
                    maxWidth = max(maxWidth, 42)
                } else {
                    let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                    height += size.height
                    maxWidth = max(maxWidth, size.width)
                }
            }
            height += spacing + 8
            let width = maxWidth + Self.horizontalContentInset * 2
            return CGSize(width: width, height: height)
        }
        let itemWidth = itemStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
        var width: CGFloat = 0
        for view in visibleSubviews {
            if view === itemScrollView {
                width += itemWidth
            } else {
                width += view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
            }
        }
        width += spacing + Self.horizontalContentInset * 2
        return CGSize(width: width, height: 70)
    }

    private func updateCornerStyleIfNeeded() {
        if isCollapsed {
            layer.cornerRadius = 16
            if layoutAxis == .vertical {
                layer.maskedCorners = [
                    .layerMinXMinYCorner,
                    .layerMaxXMinYCorner,
                    .layerMinXMaxYCorner,
                    .layerMaxXMaxYCorner
                ]
            } else {
                layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            }
            isFullWidthStyle = nil
            return
        }
        if layoutAxis == .vertical {
            layer.cornerRadius = 0
            layer.maskedCorners = []
            isFullWidthStyle = nil
            return
        }
        let availableWidth = (superview?.bounds.width ?? bounds.width) - 24
        let fullWidth = bounds.width >= availableWidth - 0.5
        guard isFullWidthStyle != fullWidth else { return }
        isFullWidthStyle = fullWidth
        if fullWidth {
            layer.cornerRadius = 0
            layer.maskedCorners = []
        } else {
            layer.cornerRadius = 16
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }
}
