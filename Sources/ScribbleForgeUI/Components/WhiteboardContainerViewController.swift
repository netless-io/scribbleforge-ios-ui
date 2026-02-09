import UIKit
import ScribbleForge

public final class WhiteboardContainerViewController: UIViewController {
    private let config: WhiteboardUIConfig
    private let stateStore: WhiteboardStateStore
    private let toolbarView = WhiteboardToolbarView()
    private let toolbarBackgroundView = UIView()
    private let stageContainer = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var whiteboardConstraints: [NSLayoutConstraint] = []
    private var toolbarConstraints: [NSLayoutConstraint] = []
    private var toolbarBackgroundConstraints: [NSLayoutConstraint] = []
    private var penSettingsView: WhiteboardPenSettingsView?
    private var penSettingsConstraints: [NSLayoutConstraint] = []
    private var backgroundSettingsView: WhiteboardBackgroundSettingsView?
    private var backgroundSettingsConstraints: [NSLayoutConstraint] = []
    private var shapeSettingsView: WhiteboardShapeSettingsView?
    private var shapeSettingsConstraints: [NSLayoutConstraint] = []
    private var dismissSettingsGesture: UILongPressGestureRecognizer?
    private let shapeToolOrder: [WhiteboardToolType] = [.rectangle, .triangle, .ellipse, .arrow, .line]
    private var lastShapeTool: WhiteboardToolType?
    private var isWhiteboardReady = false
    private var isLoadingWhiteboard = false
    private var isVerticalToolbarLayout = false

    private weak var room: Room?
    private weak var whiteboard: Whiteboard?
    private var isJoining = false
    private var hasJoined = false

    public init(config: WhiteboardUIConfig = .init()) {
        self.config = config
        self.stateStore = WhiteboardStateStore(
            initialState: WhiteboardUIState(backgroundColor: config.initialBackgroundColor)
        )
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        stop()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupToolbar()
        bindState()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateToolbarLayoutIfNeeded()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateToolbarLayoutIfNeeded()
    }

    public func start(with room: Room, autoJoin: Bool = true) {
        stop()
        self.room = room
        room.addDelegate(self)
        isLoadingWhiteboard = true
        updateLoadingState()
        if autoJoin {
            joinRoomIfNeeded(room)
        } else {
            launchWhiteboardIfNeeded(room)
        }
    }

    public func stop() {
        room?.removeDelegate(self)
        room = nil
        detachWhiteboard()
        hideAllSettings()
        isJoining = false
        hasJoined = false
        isLoadingWhiteboard = false
        updateLoadingState()
        updateToolbarVisibility()
    }

    private func setupLayout() {
        stageContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stageContainer)

        NSLayoutConstraint.activate([
            stageContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stageContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stageContainer.topAnchor.constraint(equalTo: view.topAnchor),
            stageContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .label
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupToolbar() {
        toolbarBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        toolbarBackgroundView.isHidden = !config.showToolbar
        toolbarBackgroundView.backgroundColor = config.theme.toolbarBackgroundColor
        view.addSubview(toolbarBackgroundView)

        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.isHidden = !config.showToolbar
        toolbarView.configure(allowedTools: config.allowedTools, theme: config.theme)
        toolbarView.apply(state: stateStore.state)
        toolbarView.setContentHuggingPriority(.required, for: .horizontal)
        toolbarView.setContentCompressionResistancePriority(.required, for: .horizontal)
        updateToolbarVisibility()
        toolbarBackgroundView.backgroundColor = config.theme.toolbarBackgroundColor

        toolbarView.onToolSelected = { [weak self] tool in
            guard let self else { return }
            self.hideAllSettings()
            self.whiteboard?.setCurrentTool(tool)
        }
        toolbarView.onUndo = { [weak self] in
            self?.whiteboard?.undo()
        }
        toolbarView.onRedo = { [weak self] in
            self?.whiteboard?.redo()
        }
        toolbarView.onPrevPage = { [weak self] in
            self?.whiteboard?.indexedNavigation.prevPage()
        }
        toolbarView.onNextPage = { [weak self] in
            self?.whiteboard?.indexedNavigation.nextPage()
        }
        toolbarView.onColorSettings = { [weak self] in
            self?.togglePenSettings()
        }
        toolbarView.onBackgroundColor = { [weak self] in
            self?.toggleBackgroundSettings()
        }
        toolbarView.onShapePicker = { [weak self] in
            self?.selectCurrentShapeAndShowSettings()
        }
        toolbarView.onSave = { [weak self] in
            self?.saveSnapshot()
        }
        toolbarView.onCollapsedStateChanged = { [weak self] collapsed in
            guard let self else { return }
            if collapsed {
                self.hideAllSettings()
            }
            self.applyToolbarConstraints()
            self.updateVisibleSettingsConstraints()
        }

        view.addSubview(toolbarView)
        updateToolbarLayoutIfNeeded(force: true)
    }

    private func bindState() {
        stateStore.onChange = { [weak self] state in
            guard let self else { return }
            self.toolbarView.apply(state: state)
            if let tool = state.currentTool, self.shapeToolOrder.contains(tool) {
                self.lastShapeTool = tool
            }
            if self.shapeSettingsView?.superview != nil {
                self.shapeSettingsView?.apply(selectedTool: state.currentTool)
            }
            self.updateToolbarVisibility()
        }
    }

    private func togglePenSettings() {
        if penSettingsView?.superview != nil {
            hidePenSettings()
        } else {
            hideBackgroundSettings()
            hideShapeSettings()
            showPenSettings()
        }
    }

    private func showPenSettings() {
        if penSettingsView == nil {
            let view = WhiteboardPenSettingsView(theme: config.theme)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.onColorSelected = { [weak self] color in
                self?.whiteboard?.setStrokeColor(color)
            }
            view.onWidthSelected = { [weak self] width in
                self?.whiteboard?.setStrokeWidth(width)
            }
            penSettingsView = view
        }

        guard let settingsView = penSettingsView else { return }
        if settingsView.superview == nil {
            view.addSubview(settingsView)
        }

        applyPenSettingsConstraints(for: settingsView)

        let state = stateStore.state
        settingsView.apply(selectedColor: state.strokeColor, selectedWidth: state.strokeWidth > 0 ? state.strokeWidth : nil)
        view.bringSubviewToFront(settingsView)
        view.bringSubviewToFront(toolbarView)
        installDismissGestureIfNeeded()
    }

    private func hidePenSettings() {
        penSettingsView?.removeFromSuperview()
        NSLayoutConstraint.deactivate(penSettingsConstraints)
        penSettingsConstraints = []
        updateDismissGestureIfNeeded()
    }

    private func applyPenSettingsConstraints(for settingsView: WhiteboardPenSettingsView) {
        NSLayoutConstraint.deactivate(penSettingsConstraints)
        settingsView.setLayoutAxis(isVerticalToolbarLayout ? .vertical : .horizontal)
        let preferredSize = settingsView.preferredSize
        if isVerticalToolbarLayout {
            penSettingsConstraints = [
                settingsView.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
                settingsView.trailingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: -12),
                settingsView.widthAnchor.constraint(equalToConstant: preferredSize.width),
                settingsView.heightAnchor.constraint(equalToConstant: preferredSize.height)
            ]
        } else {
            penSettingsConstraints = [
                settingsView.bottomAnchor.constraint(equalTo: toolbarView.topAnchor, constant: -12),
                settingsView.centerXAnchor.constraint(equalTo: toolbarView.centerXAnchor),
                settingsView.widthAnchor.constraint(equalToConstant: preferredSize.width),
                settingsView.heightAnchor.constraint(equalToConstant: preferredSize.height)
            ]
        }
        NSLayoutConstraint.activate(penSettingsConstraints)
    }

    private func toggleBackgroundSettings() {
        if backgroundSettingsView?.superview != nil {
            hideBackgroundSettings()
        } else {
            hidePenSettings()
            hideShapeSettings()
            showBackgroundSettings()
        }
    }

    private func showBackgroundSettings() {
        if backgroundSettingsView == nil {
            let view = WhiteboardBackgroundSettingsView(
                theme: config.theme,
                colorOptions: config.backgroundColorOptions
            )
            view.translatesAutoresizingMaskIntoConstraints = false
            view.onColorSelected = { [weak self] color in
                self?.whiteboard?.setBackgroundColor(color)
                self?.stateStore.setBackgroundColor(color)
                self?.hideBackgroundSettings()
            }
            backgroundSettingsView = view
        }

        guard let settingsView = backgroundSettingsView else { return }
        if settingsView.superview == nil {
            view.addSubview(settingsView)
        }

        applyBackgroundSettingsConstraints(for: settingsView)

        settingsView.apply(selectedColor: stateStore.state.backgroundColor)
        view.bringSubviewToFront(settingsView)
        view.bringSubviewToFront(toolbarView)
        installDismissGestureIfNeeded()
    }

    private func hideBackgroundSettings() {
        backgroundSettingsView?.removeFromSuperview()
        NSLayoutConstraint.deactivate(backgroundSettingsConstraints)
        backgroundSettingsConstraints = []
        updateDismissGestureIfNeeded()
    }

    private func applyBackgroundSettingsConstraints(for settingsView: WhiteboardBackgroundSettingsView) {
        NSLayoutConstraint.deactivate(backgroundSettingsConstraints)
        settingsView.setLayoutAxis(isVerticalToolbarLayout ? .vertical : .horizontal)
        let preferredSize = settingsView.preferredSize
        if isVerticalToolbarLayout {
            backgroundSettingsConstraints = [
                settingsView.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
                settingsView.trailingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: -12),
                settingsView.widthAnchor.constraint(equalToConstant: preferredSize.width),
                settingsView.heightAnchor.constraint(equalToConstant: preferredSize.height)
            ]
        } else {
            backgroundSettingsConstraints = [
                settingsView.bottomAnchor.constraint(equalTo: toolbarView.topAnchor, constant: -12),
                settingsView.centerXAnchor.constraint(equalTo: toolbarView.centerXAnchor),
                settingsView.widthAnchor.constraint(equalToConstant: preferredSize.width),
                settingsView.heightAnchor.constraint(equalToConstant: preferredSize.height)
            ]
        }
        NSLayoutConstraint.activate(backgroundSettingsConstraints)
    }

    private func selectCurrentShapeAndShowSettings() {
        let current = stateStore.state.currentTool
        let shapeTool = (current.flatMap { shapeToolOrder.contains($0) ? $0 : nil })
            ?? lastShapeTool
            ?? defaultShapeTool
        if let shapeTool {
            whiteboard?.setCurrentTool(shapeTool)
        }
        hidePenSettings()
        hideBackgroundSettings()
        showShapeSettings()
    }

    private func showShapeSettings() {
        if shapeSettingsView == nil {
            let view = WhiteboardShapeSettingsView(theme: config.theme)
            view.translatesAutoresizingMaskIntoConstraints = false
            view.onShapeSelected = { [weak self] tool in
                self?.whiteboard?.setCurrentTool(tool)
                self?.hideShapeSettings()
            }
            shapeSettingsView = view
        }

        guard let settingsView = shapeSettingsView else { return }
        if settingsView.superview == nil {
            view.addSubview(settingsView)
        }

        applyShapeSettingsConstraints(for: settingsView)

        settingsView.apply(selectedTool: stateStore.state.currentTool)
        view.bringSubviewToFront(settingsView)
        view.bringSubviewToFront(toolbarView)
        installDismissGestureIfNeeded()
    }

    private func hideShapeSettings() {
        shapeSettingsView?.removeFromSuperview()
        NSLayoutConstraint.deactivate(shapeSettingsConstraints)
        shapeSettingsConstraints = []
        updateDismissGestureIfNeeded()
    }

    private func applyShapeSettingsConstraints(for settingsView: WhiteboardShapeSettingsView) {
        NSLayoutConstraint.deactivate(shapeSettingsConstraints)
        settingsView.setLayoutAxis(isVerticalToolbarLayout ? .vertical : .horizontal)
        let preferredSize = settingsView.preferredSize
        if isVerticalToolbarLayout {
            shapeSettingsConstraints = [
                settingsView.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
                settingsView.trailingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: -12),
                settingsView.widthAnchor.constraint(equalToConstant: preferredSize.width),
                settingsView.heightAnchor.constraint(equalToConstant: preferredSize.height)
            ]
        } else {
            shapeSettingsConstraints = [
                settingsView.bottomAnchor.constraint(equalTo: toolbarView.topAnchor, constant: -12),
                settingsView.centerXAnchor.constraint(equalTo: toolbarView.centerXAnchor),
                settingsView.widthAnchor.constraint(equalToConstant: preferredSize.width),
                settingsView.heightAnchor.constraint(equalToConstant: preferredSize.height)
            ]
        }
        NSLayoutConstraint.activate(shapeSettingsConstraints)
    }

    private func hideAllSettings() {
        hidePenSettings()
        hideBackgroundSettings()
        hideShapeSettings()
    }

    private func updateToolbarVisibility() {
        let shouldShow = config.showToolbar && isWhiteboardReady && stateStore.state.canDraw
        toolbarView.isHidden = !shouldShow
        toolbarBackgroundView.isHidden = !shouldShow
    }

    private func shouldUseVerticalToolbarLayout() -> Bool {
        return traitCollection.userInterfaceIdiom == .phone && view.bounds.width > view.bounds.height
    }

    private func updateToolbarLayoutIfNeeded(force: Bool = false) {
        let shouldVertical = shouldUseVerticalToolbarLayout()
        guard force || shouldVertical != isVerticalToolbarLayout else { return }
        isVerticalToolbarLayout = shouldVertical
        toolbarView.setLayoutAxis(shouldVertical ? .vertical : .horizontal)
        applyToolbarConstraints()
        updateVisibleSettingsConstraints()
    }

    private func applyToolbarConstraints() {
        NSLayoutConstraint.deactivate(toolbarConstraints)
        NSLayoutConstraint.deactivate(toolbarBackgroundConstraints)
        if isVerticalToolbarLayout && toolbarView.isCollapsedState {
            toolbarBackgroundView.layer.cornerRadius = 16
            toolbarBackgroundView.layer.cornerCurve = .continuous
            toolbarBackgroundView.layer.masksToBounds = true
        } else {
            toolbarBackgroundView.layer.cornerRadius = 0
            toolbarBackgroundView.layer.masksToBounds = false
        }
        if isVerticalToolbarLayout {
            if toolbarView.isCollapsedState {
                toolbarConstraints = [
                    toolbarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                    toolbarView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                    toolbarView.heightAnchor.constraint(equalToConstant: 70),
                    toolbarView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor),
                    toolbarView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor)
                ]
            } else {
                toolbarConstraints = [
                    toolbarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                    toolbarView.topAnchor.constraint(equalTo: view.topAnchor),
                    toolbarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    toolbarView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor)
                ]
            }
            toolbarBackgroundConstraints = [
                toolbarBackgroundView.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor),
                toolbarBackgroundView.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor),
                toolbarBackgroundView.topAnchor.constraint(equalTo: toolbarView.topAnchor),
                toolbarBackgroundView.bottomAnchor.constraint(equalTo: toolbarView.bottomAnchor)
            ]
        } else {
            toolbarConstraints = [
                toolbarView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
                toolbarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                toolbarView.widthAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor),
                toolbarView.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor),
                toolbarView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor)
            ]
            toolbarBackgroundConstraints = [
                toolbarBackgroundView.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor),
                toolbarBackgroundView.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor),
                toolbarBackgroundView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
                toolbarBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ]
        }
        NSLayoutConstraint.activate(toolbarConstraints)
        NSLayoutConstraint.activate(toolbarBackgroundConstraints)
        view.layoutIfNeeded()
    }

    private func updateVisibleSettingsConstraints() {
        if let settingsView = penSettingsView, settingsView.superview != nil {
            applyPenSettingsConstraints(for: settingsView)
        }
        if let settingsView = backgroundSettingsView, settingsView.superview != nil {
            applyBackgroundSettingsConstraints(for: settingsView)
        }
        if let settingsView = shapeSettingsView, settingsView.superview != nil {
            applyShapeSettingsConstraints(for: settingsView)
        }
    }

    private func updateLoadingState() {
        let shouldShow = isLoadingWhiteboard && !isWhiteboardReady
        if shouldShow {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private var defaultShapeTool: WhiteboardToolType? {
        return shapeToolOrder.first { config.allowedTools.contains($0) }
    }

    private func installDismissGestureIfNeeded() {
        guard dismissSettingsGesture == nil else { return }
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleDismissGesture(_:)))
        gesture.minimumPressDuration = 0
        gesture.allowableMovement = .greatestFiniteMagnitude
        gesture.cancelsTouchesInView = false
        gesture.delaysTouchesBegan = false
        gesture.delegate = self
        stageContainer.addGestureRecognizer(gesture)
        dismissSettingsGesture = gesture
    }

    private func updateDismissGestureIfNeeded() {
        guard dismissSettingsGesture != nil else { return }
        if !hasVisibleSettings {
            if let gesture = dismissSettingsGesture {
                stageContainer.removeGestureRecognizer(gesture)
            }
            dismissSettingsGesture = nil
        }
    }

    private var hasVisibleSettings: Bool {
        return penSettingsView?.superview != nil
            || backgroundSettingsView?.superview != nil
            || shapeSettingsView?.superview != nil
    }

    @objc private func handleDismissGesture(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            if hasVisibleSettings {
                hideAllSettings()
            }
        }
    }

    private func saveSnapshot() {
        guard let whiteboard else { return }
        whiteboard.rasterize { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    self?.presentShareSheet(for: image)
                case .failure(let error):
                    print("[ScribbleForgeUI] snapshot failed: \(error)")
                }
            }
        }
    }

    private func presentShareSheet(for image: UIImage) {
        let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let popover = controller.popoverPresentationController,
           let anchor = toolbarView.actionButtonFrame(for: .save, in: view)
        {
            popover.sourceView = view
            popover.sourceRect = anchor
        }
        present(controller, animated: true)
    }

    private func launchWhiteboardIfNeeded(_ room: Room) {
        if let existing = room.applicationManager.apps().compactMap({ $0 as? Whiteboard }).first(where: { $0.appId == config.whiteboardAppId }) {
            attachWhiteboard(existing)
            return
        }

        config.launch(room, config.whiteboardAppId)
    }

    private func joinRoomIfNeeded(_ room: Room) {
        guard !isJoining, !hasJoined else { return }
        isJoining = true
        room.joinRoom { [weak self] result in
            guard let self else { return }
            self.isJoining = false
            switch result {
            case .success:
                self.hasJoined = true
                self.launchWhiteboardIfNeeded(room)
            case .failure:
                self.hasJoined = false
                self.isLoadingWhiteboard = false
                self.updateLoadingState()
            }
            let mapped: Result<Void, Error> = result.mapError { $0 as Error }.map { _ in () }
            self.config.onJoinResult?(mapped)
        }
    }

    private func detachWhiteboard() {
        whiteboard?.delegate = nil
        whiteboard?.applicationView?.removeFromSuperview()
        whiteboard = nil
        NSLayoutConstraint.deactivate(whiteboardConstraints)
        whiteboardConstraints = []
        isWhiteboardReady = false
    }

    private func attachWhiteboard(_ whiteboard: Whiteboard) {
        detachWhiteboard()
        self.whiteboard = whiteboard
        stateStore.bind(whiteboard: whiteboard, roomUserId: room?.userId)
        whiteboard.setBackgroundColor(stateStore.state.backgroundColor)
        isWhiteboardReady = true
        isLoadingWhiteboard = false
        updateLoadingState()
        updateToolbarVisibility()

        guard let applicationView = whiteboard.applicationView else { return }
        applicationView.isOpaque = false
        applicationView.backgroundColor = .clear
        applicationView.removeFromSuperview()
        applicationView.translatesAutoresizingMaskIntoConstraints = false
        stageContainer.addSubview(applicationView)
        stageContainer.sendSubviewToBack(applicationView)

        NSLayoutConstraint.deactivate(whiteboardConstraints)
        let aspectConstraint = applicationView.widthAnchor.constraint(equalTo: applicationView.heightAnchor, multiplier: config.whiteboardAspectRatio)
        let widthFit = applicationView.widthAnchor.constraint(equalTo: stageContainer.widthAnchor)
        widthFit.priority = .defaultHigh
        let heightFit = applicationView.heightAnchor.constraint(equalTo: stageContainer.heightAnchor)
        heightFit.priority = .defaultHigh
        whiteboardConstraints = [
            applicationView.centerXAnchor.constraint(equalTo: stageContainer.centerXAnchor),
            applicationView.centerYAnchor.constraint(equalTo: stageContainer.centerYAnchor),
            applicationView.widthAnchor.constraint(lessThanOrEqualTo: stageContainer.widthAnchor),
            applicationView.heightAnchor.constraint(lessThanOrEqualTo: stageContainer.heightAnchor),
            widthFit,
            heightFit,
            aspectConstraint
        ]
        NSLayoutConstraint.activate(whiteboardConstraints)
    }
}

extension WhiteboardContainerViewController: RoomDelegate {
    public func roomApplicationDidLaunch(_: Room, application: any Application) {
        guard let whiteboard = application as? Whiteboard else { return }
        guard whiteboard.appId == config.whiteboardAppId else { return }
        attachWhiteboard(whiteboard)
    }

    public func roomApplicationDidTerminal(_: Room, application app: any Application) {
        guard app.appId == config.whiteboardAppId else { return }
        detachWhiteboard()
        isLoadingWhiteboard = false
        updateLoadingState()
        updateToolbarVisibility()
    }

    public func roomUserWritableUpdate(_ room: Room, userId: String, writable: Bool) {
        guard userId == room.userId else { return }
        stateStore.setWritable(writable)
    }

    public func roomConnectionStateDidUpdate(_: Room, connectionState _: NetworkConnectionState, info _: [String: Any]) {}

    public func roomUserJoinRoom(_: Room, user _: RoomUser) {}

    public func roomUserLeaveRoom(_: Room, userId _: String) {}
}

extension WhiteboardContainerViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
