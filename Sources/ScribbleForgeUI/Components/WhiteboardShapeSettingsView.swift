import UIKit
import ScribbleForge

final class WhiteboardShapeSettingsView: UIView {
    private struct ShapeOption: Equatable {
        let tool: WhiteboardToolType
        let imageName: String
    }

    private static let itemWidth: CGFloat = 46
    private static let itemHeight: CGFloat = 42
    private static let itemSpacing: CGFloat = 10
    private static let containerPadding: CGFloat = 0
    private static let stackPadding: CGFloat = 7

    var onShapeSelected: ((WhiteboardToolType) -> Void)?

    private let shapeOptions: [ShapeOption] = [
        .init(tool: .rectangle, imageName: "fcr_whiteboard_shap_square"),
        .init(tool: .triangle, imageName: "fcr_whiteboard_shap_triangle"),
        .init(tool: .ellipse, imageName: "fcr_whiteboard_shap_circle"),
        .init(tool: .arrow, imageName: "fcr_whiteboard_shap_arrow"),
        .init(tool: .line, imageName: "fcr_whiteboard_shap_line")
    ]

    private let rowContainer = UIView()
    private let shapeStack = UIStackView()
    private var shapeButtons: [UIButton] = []
    private var theme: ScribbleForgeUISkin
    private var layoutAxis: NSLayoutConstraint.Axis = .horizontal

    var preferredSize: CGSize {
        let contentLength = CGFloat(shapeOptions.count) * Self.itemWidth
            + CGFloat(max(shapeOptions.count - 1, 0)) * Self.itemSpacing
        let insets = 2 * (Self.containerPadding + Self.stackPadding)
        if layoutAxis == .vertical {
            let width = Self.itemWidth + insets
            let height = CGFloat(shapeOptions.count) * Self.itemHeight
                + CGFloat(max(shapeOptions.count - 1, 0)) * Self.itemSpacing
                + insets
            return CGSize(width: width, height: height)
        }
        let width = contentLength + insets
        let height = Self.itemHeight + insets
        return CGSize(width: width, height: height)
    }

    init(theme: ScribbleForgeUISkin = .default) {
        self.theme = theme
        super.init(frame: .zero)
        setupView()
    }

    override init(frame: CGRect) {
        self.theme = .default
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        self.theme = .default
        super.init(coder: coder)
        setupView()
    }

    func apply(selectedTool: WhiteboardToolType?) {
        for (index, button) in shapeButtons.enumerated() {
            let option = shapeOptions[index]
            let isSelected = selectedTool == option.tool
            updateShapeButton(button, selected: isSelected)
        }
    }

    func setLayoutAxis(_ axis: NSLayoutConstraint.Axis) {
        guard layoutAxis != axis else { return }
        layoutAxis = axis
        shapeStack.axis = axis
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    private func setupView() {
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 6)

        rowContainer.translatesAutoresizingMaskIntoConstraints = false
        rowContainer.layer.cornerRadius = 12

        shapeStack.axis = .horizontal
        shapeStack.alignment = .center
        shapeStack.distribution = .fill
        shapeStack.spacing = Self.itemSpacing
        shapeStack.translatesAutoresizingMaskIntoConstraints = false

        applyDynamicColors()

        addSubview(rowContainer)
        rowContainer.addSubview(shapeStack)

        NSLayoutConstraint.activate([
            rowContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.containerPadding),
            rowContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.containerPadding),
            rowContainer.topAnchor.constraint(equalTo: topAnchor, constant: Self.containerPadding),
            rowContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.containerPadding),

            shapeStack.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor, constant: Self.stackPadding),
            shapeStack.trailingAnchor.constraint(equalTo: rowContainer.trailingAnchor, constant: -Self.stackPadding),
            shapeStack.topAnchor.constraint(equalTo: rowContainer.topAnchor, constant: Self.stackPadding),
            shapeStack.bottomAnchor.constraint(equalTo: rowContainer.bottomAnchor, constant: -Self.stackPadding)
        ])

        buildButtons()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        applyDynamicColors()
        apply(selectedTool: currentSelectedTool())
    }

    private func applyDynamicColors() {
        backgroundColor = theme.colors.popupBackground
        layer.borderColor = theme.colors.popupBorder.resolvedColor(with: traitCollection).cgColor
        layer.shadowColor = theme.colors.popupShadow.resolvedColor(with: traitCollection).cgColor
        rowContainer.backgroundColor = theme.colors.popupContentBackground
    }

    private func buildButtons() {
        shapeButtons = shapeOptions.enumerated().map { index, option in
            let button = UIButton(type: .custom)
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: Self.itemWidth).isActive = true
            button.heightAnchor.constraint(equalToConstant: Self.itemHeight).isActive = true
            button.adjustsImageWhenHighlighted = false
            button.accessibilityLabel = option.tool.rawValue
            button.tintColor = theme.toolbarTintColor
            if let image = ScribbleForgeUIResources.image(named: option.imageName) {
                button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
            }
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
            button.imageView?.contentMode = .scaleAspectFit
            button.layer.cornerRadius = 8
            button.layer.cornerCurve = .continuous
            button.addTarget(self, action: #selector(shapeTapped(_:)), for: .touchUpInside)
            shapeStack.addArrangedSubview(button)
            return button
        }
    }

    @objc private func shapeTapped(_ sender: UIButton) {
        guard sender.tag >= 0 && sender.tag < shapeOptions.count else { return }
        let tool = shapeOptions[sender.tag].tool
        apply(selectedTool: tool)
        onShapeSelected?(tool)
    }

    private func updateShapeButton(_ button: UIButton, selected: Bool) {
        if selected {
            button.backgroundColor = theme.colors.toolbarSelectionFill
            button.tintColor = theme.colors.toolbarSelectionBorder
        } else {
            button.backgroundColor = .clear
            button.tintColor = theme.toolbarTintColor
        }
        button.layer.borderWidth = 0
        button.isSelected = selected
    }

    private func currentSelectedTool() -> WhiteboardToolType? {
        guard let index = shapeButtons.firstIndex(where: { $0.isSelected }) else { return nil }
        return shapeOptions[index].tool
    }
}
