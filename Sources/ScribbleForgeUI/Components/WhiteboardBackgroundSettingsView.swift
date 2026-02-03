import UIKit

final class WhiteboardBackgroundSettingsView: UIView {
    private static let itemWidth: CGFloat = 108
    private static let itemHeight: CGFloat = 62
    private static let itemImageInset: CGFloat = 4
    private static let selectionBorderWidth: CGFloat = 2
    private static let outerCornerRadius: CGFloat = 12
    private static let innerCornerRadius: CGFloat = 8
    private static let itemSpacing: CGFloat = 10
    private static let containerPadding: CGFloat = 0
    private static let stackPadding: CGFloat = 12

    var onColorSelected: ((UIColor) -> Void)?

    private let colorOptions: [WhiteboardColorOption] = [
        .init(id: "whiteboard", color: .white),
        .init(id: "black", color: UIColor.black.withAlphaComponent(0.8)),
        .init(id: "green", color: UIColor(sfHex: "#5A7D75")!)
    ]
    private let colorStack = UIStackView()
    private var colorButtons: [UIButton] = []
    private var theme: ScribbleForgeUISkin

    var preferredWidth: CGFloat {
        let contentWidth = CGFloat(colorOptions.count) * Self.itemWidth
            + CGFloat(max(colorOptions.count - 1, 0)) * Self.itemSpacing
        return contentWidth + 2 * (Self.containerPadding + Self.stackPadding)
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

    func apply(selectedColor: UIColor?) {
        let targetColor: UIColor?
        if let selectedColor, selectedColor.cgColor.alpha > 0.01 {
            targetColor = selectedColor
        } else {
            targetColor = nil
        }
        let selectedIndex = colorOptions.firstIndex { option in
            if let targetColor {
                return targetColor.isEqual(option.color)
            }
            return false
        } ?? 0
        for (index, button) in colorButtons.enumerated() {
            updateColorButton(button, selected: index == selectedIndex)
        }
        setNeedsLayout()
    }

    private func setupView() {
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 6)

        colorStack.axis = .horizontal
        colorStack.alignment = .center
        colorStack.distribution = .fill
        colorStack.spacing = Self.itemSpacing
        colorStack.translatesAutoresizingMaskIntoConstraints = false

        applyDynamicColors()

        addSubview(colorStack)

        NSLayoutConstraint.activate([
            colorStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.containerPadding + Self.stackPadding),
            colorStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(Self.containerPadding + Self.stackPadding)),
            colorStack.topAnchor.constraint(equalTo: topAnchor, constant: Self.containerPadding),
            colorStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.containerPadding)
        ])

        buildButtons()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        applyDynamicColors()
        apply(selectedColor: currentSelectedColor())
    }

    private func applyDynamicColors() {
        backgroundColor = theme.colors.popupBackground
        layer.borderColor = theme.colors.popupBorder.resolvedColor(with: traitCollection).cgColor
        layer.shadowColor = theme.colors.popupShadow.resolvedColor(with: traitCollection).cgColor
    }

    private func buildButtons() {
        colorButtons = colorOptions.enumerated().map { index, option in
            let button = UIButton(type: .custom)
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: Self.itemWidth).isActive = true
            button.heightAnchor.constraint(equalToConstant: Self.itemHeight).isActive = true
            button.layer.cornerRadius = Self.innerCornerRadius
            button.layer.cornerCurve = .continuous
            button.clipsToBounds = false
            button.adjustsImageWhenHighlighted = false
            button.accessibilityLabel = option.id
            button.backgroundColor = .clear
            button.setImage(renderItemImage(color: option.color, selected: false, isWhite: option.id == "whiteboard"), for: .normal)
            button.imageView?.contentMode = .scaleToFill
            button.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
            colorStack.addArrangedSubview(button)
            return button
        }
    }

    @objc private func colorTapped(_ sender: UIButton) {
        guard sender.tag >= 0 && sender.tag < colorOptions.count else { return }
        let color = colorOptions[sender.tag].color
        apply(selectedColor: color)
        onColorSelected?(color)
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func updateColorButton(_ button: UIButton, selected: Bool) {
        let index = button.tag
        if index >= 0 && index < colorOptions.count {
            let isWhite = colorOptions[index].id == "whiteboard"
            let image = renderItemImage(color: colorOptions[index].color, selected: selected, isWhite: isWhite)
            button.setImage(image, for: .normal)
        }
        button.isSelected = selected
    }

    private func renderItemImage(color: UIColor, selected: Bool, isWhite: Bool) -> UIImage? {
        let size = CGSize(width: Self.itemWidth, height: Self.itemHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let fullRect = CGRect(origin: .zero, size: size)
            let fillRect = fullRect.inset(by: .init(top: 4, left: 4, bottom: 4, right: 4))
            let fillPath = UIBezierPath(roundedRect: fillRect, cornerRadius: Self.innerCornerRadius)
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.addPath(fillPath.cgPath)
            ctx.cgContext.fillPath()
            if selected {
                let borderRect = fullRect.insetBy(dx: Self.selectionBorderWidth / 2, dy: Self.selectionBorderWidth / 2)
                let borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: Self.outerCornerRadius)
                let borderColor = theme.colors.backgroundSelectionBorder.resolvedColor(with: traitCollection).cgColor
                ctx.cgContext.setStrokeColor(borderColor)
                ctx.cgContext.setLineWidth(Self.selectionBorderWidth)
                ctx.cgContext.addPath(borderPath.cgPath)
                ctx.cgContext.strokePath()
            }

            guard selected, let check = ScribbleForgeUIResources.image(named: "fcr_chooseit") else { return }
            let checkImage: UIImage
            if isWhite {
                let borderColor = theme.colors.backgroundSelectionBorder.resolvedColor(with: traitCollection)
                checkImage = check.withTintColor(borderColor, renderingMode: .alwaysOriginal)
            } else {
                checkImage = check.withRenderingMode(.alwaysOriginal)
            }
            let origin = CGPoint(
                x: (size.width - check.size.width) / 2,
                y: (size.height - check.size.height) / 2
            )
            checkImage.draw(in: CGRect(origin: origin, size: check.size))
        }
    }

    private func currentSelectedColor() -> UIColor? {
        guard let index = colorButtons.firstIndex(where: { $0.isSelected }) else { return nil }
        return colorOptions[index].color
    }
}
