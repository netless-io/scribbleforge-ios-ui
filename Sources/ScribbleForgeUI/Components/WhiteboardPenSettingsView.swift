import UIKit

final class WhiteboardPenSettingsView: UIView {
    struct WidthOption: Equatable {
        let id: String
        let width: Float
        let dotSize: CGFloat
    }

    private static let itemSize: CGFloat = 32
    private static let itemSpacing: CGFloat = 10
    private static let containerPadding: CGFloat = 0
    private static let stackPadding: CGFloat = 7
    private static let sectionSpacing: CGFloat = 12

    var onColorSelected: ((UIColor) -> Void)?
    var onWidthSelected: ((Float) -> Void)?

    private var colorOptions: [WhiteboardColorOption]

    private let widthOptions: [WidthOption] = [
        .init(id: "small", width: 2, dotSize: 6),
        .init(id: "medium", width: 4, dotSize: 10),
        .init(id: "large", width: 8, dotSize: 14)
    ]

    private let rowContainer = UIView()
    private let colorStack = UIStackView()
    private let widthStack = UIStackView()
    private let separatorView = UIView()

    private var colorButtons: [UIButton] = []
    private var widthButtons: [UIButton] = []
    private var theme: ScribbleForgeUISkin

    var preferredWidth: CGFloat {
        let widthContent = CGFloat(widthOptions.count) * Self.itemSize
            + CGFloat(max(widthOptions.count - 1, 0)) * Self.itemSpacing
        let colorContent = CGFloat(colorOptions.count) * Self.itemSize
            + CGFloat(max(colorOptions.count - 1, 0)) * Self.itemSpacing
        return widthContent + colorContent + Self.sectionSpacing * 2 + 1 + 2 * (Self.containerPadding + Self.stackPadding)
    }

    init(theme: ScribbleForgeUISkin = .default) {
        self.theme = theme
        self.colorOptions = WhiteboardColorPalette.options(using: theme.colors.palette)
        super.init(frame: .zero)
        setupView()
    }

    override init(frame: CGRect) {
        self.theme = .default
        self.colorOptions = WhiteboardColorPalette.options(using: ScribbleForgeUISkin.Palette.default)
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        self.theme = .default
        self.colorOptions = WhiteboardColorPalette.options(using: ScribbleForgeUISkin.Palette.default)
        super.init(coder: coder)
        setupView()
    }

    func apply(selectedColor: UIColor?, selectedWidth: Float?) {
        for (index, button) in colorButtons.enumerated() {
            let isSelected = selectedColor.map { $0.isEqual(colorOptions[index].color) } ?? false
            updateColorButton(button, selected: isSelected)
        }
        for (index, button) in widthButtons.enumerated() {
            let isSelected = selectedWidth.map { abs($0 - widthOptions[index].width) < 0.01 } ?? false
            updateWidthButton(button, selected: isSelected, dotSize: widthOptions[index].dotSize)
        }
    }

    private func setupView() {
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 6)

        rowContainer.translatesAutoresizingMaskIntoConstraints = false
        rowContainer.layer.cornerRadius = 12

        colorStack.axis = .horizontal
        colorStack.alignment = .center
        colorStack.distribution = .fill
        colorStack.spacing = Self.itemSpacing
        colorStack.translatesAutoresizingMaskIntoConstraints = false
        colorStack.setContentHuggingPriority(.required, for: .horizontal)
        colorStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        widthStack.axis = .horizontal
        widthStack.alignment = .center
        widthStack.distribution = .fill
        widthStack.spacing = Self.itemSpacing
        widthStack.translatesAutoresizingMaskIntoConstraints = false
        widthStack.setContentHuggingPriority(.required, for: .horizontal)
        widthStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        applyDynamicColors()

        addSubview(rowContainer)
        rowContainer.addSubview(widthStack)
        rowContainer.addSubview(separatorView)
        rowContainer.addSubview(colorStack)

        NSLayoutConstraint.activate([
            rowContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.containerPadding),
            rowContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.containerPadding),
            rowContainer.topAnchor.constraint(equalTo: topAnchor, constant: Self.containerPadding),
            rowContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.containerPadding),
            rowContainer.heightAnchor.constraint(equalToConstant: 50),

            widthStack.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor, constant: Self.stackPadding),
            widthStack.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),

            separatorView.leadingAnchor.constraint(equalTo: widthStack.trailingAnchor, constant: Self.sectionSpacing),
            separatorView.trailingAnchor.constraint(equalTo: colorStack.leadingAnchor, constant: -Self.sectionSpacing),
            separatorView.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 1),
            separatorView.heightAnchor.constraint(equalToConstant: 24),

            colorStack.trailingAnchor.constraint(equalTo: rowContainer.trailingAnchor, constant: -Self.stackPadding),
            colorStack.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor)
        ])

        buildButtons()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        applyDynamicColors()
        apply(selectedColor: currentSelectedColor(), selectedWidth: currentSelectedWidth())
    }

    private func applyDynamicColors() {
        backgroundColor = theme.colors.popupBackground
        layer.borderColor = theme.colors.popupBorder.resolvedColor(with: traitCollection).cgColor
        layer.shadowColor = theme.colors.popupShadow.resolvedColor(with: traitCollection).cgColor
        rowContainer.backgroundColor = theme.colors.popupContentBackground
        separatorView.backgroundColor = theme.colors.toolbarBorder
        widthButtons.forEach { $0.tintColor = theme.colors.widthRing }
    }

    private func buildButtons() {
        colorButtons = colorOptions.enumerated().map { index, option in
            let button = UIButton(type: .custom)
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: Self.itemSize).isActive = true
            button.heightAnchor.constraint(equalToConstant: Self.itemSize).isActive = true
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.adjustsImageWhenHighlighted = false
            button.accessibilityLabel = option.id
            button.tintColor = option.color
            button.setBackgroundImage(frameImage(selected: false), for: .normal)
            button.setImage(nil, for: .normal)

            button.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
            colorStack.addArrangedSubview(button)
            return button
        }

        widthButtons = widthOptions.enumerated().map { index, option in
            let button = UIButton(type: .custom)
            button.tag = index
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: Self.itemSize).isActive = true
            button.heightAnchor.constraint(equalToConstant: Self.itemSize).isActive = true
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            button.adjustsImageWhenHighlighted = false
            button.tintColor = theme.colors.widthRing
            button.accessibilityLabel = option.id
            button.setImage(widthImage(selected: false, dotSize: option.dotSize), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.addTarget(self, action: #selector(widthTapped(_:)), for: .touchUpInside)
            widthStack.addArrangedSubview(button)
            return button
        }
    }

    @objc private func colorTapped(_ sender: UIButton) {
        guard sender.tag >= 0 && sender.tag < colorOptions.count else { return }
        let color = colorOptions[sender.tag].color
        apply(selectedColor: color, selectedWidth: currentSelectedWidth())
        onColorSelected?(color)
    }

    @objc private func widthTapped(_ sender: UIButton) {
        guard sender.tag >= 0 && sender.tag < widthOptions.count else { return }
        let width = widthOptions[sender.tag].width
        apply(selectedColor: currentSelectedColor(), selectedWidth: width)
        onWidthSelected?(width)
    }

    private func currentSelectedColor() -> UIColor? {
        guard let index = colorButtons.firstIndex(where: { $0.isSelected }) else { return nil }
        return colorOptions[index].color
    }

    private func currentSelectedWidth() -> Float? {
        guard let index = widthButtons.firstIndex(where: { $0.isSelected }) else { return nil }
        return widthOptions[index].width
    }

    private func updateWidthButton(_ button: UIButton, selected: Bool, dotSize: CGFloat) {
        button.setImage(widthImage(selected: selected, dotSize: dotSize), for: .normal)
        button.isSelected = selected
    }

    private func widthImage(selected: Bool, dotSize: CGFloat) -> UIImage? {
        let size = CGSize(width: Self.itemSize, height: Self.itemSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            if selected {
                let ringRect = CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24)
                let ringColor = theme.colors.widthRing.resolvedColor(with: traitCollection).cgColor
                ctx.cgContext.setStrokeColor(ringColor)
                ctx.cgContext.setLineWidth(2)
                ctx.cgContext.strokeEllipse(in: ringRect)
            }
            let dotRect = CGRect(x: center.x - dotSize / 2, y: center.y - dotSize / 2, width: dotSize, height: dotSize)
            let dotColor = theme.colors.widthDot.resolvedColor(with: traitCollection).cgColor
            ctx.cgContext.setFillColor(dotColor)
            ctx.cgContext.fillEllipse(in: dotRect)
        }
    }

    private func updateColorButton(_ button: UIButton, selected: Bool) {
        let index = button.tag
        if index >= 0 && index < colorOptions.count {
            button.tintColor = colorOptions[index].color
        }
        button.setBackgroundImage(frameImage(selected: selected), for: .normal)
        button.isSelected = selected
    }

    private func frameImage(selected: Bool) -> UIImage? {
        let name = selected ? "fcr_colorshow" : "fcr_colorshow2"
        return ScribbleForgeUIResources.image(named: name)?.withRenderingMode(.alwaysTemplate)
    }
}
