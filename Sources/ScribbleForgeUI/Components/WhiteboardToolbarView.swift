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

    private enum ToolbarItem: Hashable {
        case tool(WhiteboardToolType)
        case action(WhiteboardToolbarAction)
    }

    private let containerStack = UIStackView()
    private let itemScrollView = UIScrollView()
    private let itemStack = UIStackView()
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

    private let closeButton = UIButton(type: .system)
    private let expandButton = UIButton(type: .system)
    private let closeSeparator = UIView()
    private var isCollapsed = false
    private var isFullWidthStyle: Bool?

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
        closeButton.tintColor = normalTint
        updateShapePickerSelection(for: state.currentTool, enabled: state.canDraw)
        updateColorSettingsIcon(color: state.strokeColor ?? normalTint)
    }

    private func setupView() {
        layer.cornerRadius = 0
        layer.masksToBounds = true

        containerStack.axis = .horizontal
        containerStack.spacing = 12
        containerStack.alignment = .center
        containerStack.distribution = .fill
        containerStack.translatesAutoresizingMaskIntoConstraints = false

        itemScrollView.translatesAutoresizingMaskIntoConstraints = false
        itemScrollView.showsHorizontalScrollIndicator = false
        itemScrollView.alwaysBounceHorizontal = true
        itemScrollView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        itemScrollView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        itemScrollView.heightAnchor.constraint(equalToConstant: 42).isActive = true

        itemStack.axis = .horizontal
        itemStack.spacing = 20
        itemStack.alignment = .center
        itemStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerStack)
        containerStack.addArrangedSubview(itemScrollView)
        containerStack.addArrangedSubview(closeSeparator)
        containerStack.addArrangedSubview(closeButton)
        containerStack.addArrangedSubview(expandButton)

        itemScrollView.addSubview(itemStack)

        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            itemStack.leadingAnchor.constraint(equalTo: itemScrollView.contentLayoutGuide.leadingAnchor),
            itemStack.trailingAnchor.constraint(equalTo: itemScrollView.contentLayoutGuide.trailingAnchor),
            itemStack.topAnchor.constraint(equalTo: itemScrollView.contentLayoutGuide.topAnchor),
            itemStack.bottomAnchor.constraint(equalTo: itemScrollView.contentLayoutGuide.bottomAnchor),
            itemStack.heightAnchor.constraint(equalTo: itemScrollView.frameLayoutGuide.heightAnchor)
        ])
        heightAnchor.constraint(equalToConstant: 70).isActive = true

        setupActionButtons()
        applyTheme()
    }

    private func setupActionButtons() {
        configureResourceButton(closeButton, imageName: "fcr_close2", templated: true, selector: #selector(closeTapped))
        configureResourceButton(expandButton, imageName: "fcr_mobile_whiteboardedit", templated: false, selector: #selector(expandTapped))
        expandButton.isHidden = true

        closeSeparator.translatesAutoresizingMaskIntoConstraints = false
        closeSeparator.backgroundColor = theme.colors.toolbarBorder
        closeSeparator.widthAnchor.constraint(equalToConstant: 1).isActive = true
        closeSeparator.heightAnchor.constraint(equalToConstant: 26).isActive = true
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
        closeSeparator.backgroundColor = theme.colors.toolbarBorder
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
        let normalTint = theme.toolbarTintColor
        actionButtons.values.forEach { $0.tintColor = normalTint }
        closeButton.tintColor = normalTint
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
            return "fcr_mobile_whiteboard_revoke"
        case .redo:
            return "fcr_mobile_whiteboardedit"
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
        closeSeparator.isHidden = collapsed
        closeButton.isHidden = collapsed
        expandButton.isHidden = !collapsed
        invalidateIntrinsicContentSize()
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

    @objc private func expandTapped() {
        setCollapsed(false)
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
        }
    }

    public override var intrinsicContentSize: CGSize {
        let itemWidth = itemStack.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
        let visibleSubviews = containerStack.arrangedSubviews.filter { !$0.isHidden }
        let spacing = CGFloat(max(visibleSubviews.count - 1, 0)) * containerStack.spacing
        var width: CGFloat = 0
        for view in visibleSubviews {
            if view === itemScrollView {
                width += itemWidth
            } else {
                width += view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width
            }
        }
        width += spacing + 24
        return CGSize(width: width, height: 70)
    }

    private func updateCornerStyleIfNeeded() {
        let availableWidth = (superview?.safeAreaLayoutGuide.layoutFrame.width ?? bounds.width) - 24
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
