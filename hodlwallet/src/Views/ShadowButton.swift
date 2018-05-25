//
//  ShadowButton.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-11-15.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

enum ButtonType {
    case primary
    case secondary
    case tertiary
    case blackTransparent
    case search
}

private let minTargetSize: CGFloat = 48.0

class ShadowButton: UIControl {

    init(title: String, type: ButtonType) {
        self.title = title
        self.type = type
        self.imageColor = .whiteTint
        self.backColor = .grayBackground
        super.init(frame: .zero)
        accessibilityLabel = title
        setupViews()
    }

    init(title: String, type: ButtonType, image: UIImage) {
        self.title = title
        self.type = type
        self.image = image
        self.imageColor = .whiteTint
        self.backColor = .grayBackground
        super.init(frame: .zero)
        accessibilityLabel = title
        setupViews()
    }
    
    init(title: String, type: ButtonType, image: UIImage, imageColor: UIColor, backColor: UIColor) {
        self.title = title
        self.type = type
        self.image = image
        self.imageColor = imageColor
        self.backColor = backColor
        super.init(frame: .zero)
        accessibilityLabel = title
        setupNewViews()
    }

    var isToggleable = false
    var title: String {
        didSet {
            label.text = title
        }
    }
    var image: UIImage? {
        didSet {
            imageView?.image = image
        }
    }

    private let imageColor: UIColor
    private let backColor: UIColor
    private let type: ButtonType
    private let container = UIView()
    private let shadowView = UIView()
    private let label = UILabel()
    private let shadowYOffset: CGFloat = 4.0
    private let cornerRadius: CGFloat = 0.0
    private var imageView: UIImageView?

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                UIView.animate(withDuration: 0.04, animations: {
                    let shrink = CATransform3DMakeScale(0.97, 0.97, 1.0)
                    let translate = CATransform3DTranslate(shrink, 0, 4.0, 0)
                    self.container.layer.transform = translate
                })
            } else {
                UIView.animate(withDuration: 0.04, animations: {
                    self.container.transform = CGAffineTransform.identity
                })
            }
        }
    }

    override var isSelected: Bool {
        didSet {
            guard isToggleable else { return }
            if type == .search {
                if isSelected {
                    container.layer.borderColor = UIColor.gradientStart.cgColor
                    imageView?.tintColor = .gradientStart
                    label.textColor = .gradientStart
                } else {
                    setColors()
                }
            }
        }
    }

    private func setupViews() {
        addShadowView()
        addContent()
        setColors()
        addTarget(self, action: #selector(ShadowButton.touchUpInside), for: .touchUpInside)
        setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
    }
    
    private func setupNewViews() {
        addShadowView()
        addContent()
        setNewColors()
        addTarget(self, action: #selector(ShadowButton.touchUpInside), for: .touchUpInside)
        setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)
    }

    private func addShadowView() {
        addSubview(shadowView)
        shadowView.constrain([
            NSLayoutConstraint(item: shadowView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 0.5, constant: 0.0),
            shadowView.constraint(.bottom, toView: self),
            shadowView.constraint(.centerX, toView: self),
            NSLayoutConstraint(item: shadowView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 0.8, constant: 0.0) ])
        if type == .primary || type == .secondary {
            shadowView.layer.cornerRadius = 0.0
        } else {
            shadowView.layer.cornerRadius = 4.0
        }
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
        shadowView.backgroundColor = .white
        shadowView.isUserInteractionEnabled = false
    }

    private func addContent() {
        addSubview(container)
        container.backgroundColor = .primaryButton
        container.layer.cornerRadius = cornerRadius
        container.isUserInteractionEnabled = false
        container.constrain(toSuperviewEdges: nil)
        label.text = title
        label.textColor = .white
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        label.font = UIFont.customMedium(size: 16.0)
        configureContentType()
    }

    private func configureContentType() {
        if let icon = image {
            setupImageOption(icon: icon)
        } else {
            setupLabelOnly()
        }
    }

    private func setupImageOption(icon: UIImage) {
        let content = UIView()
        let iconImageView = UIImageView(image: icon.withRenderingMode(.alwaysTemplate))
        iconImageView.contentMode = .scaleAspectFit
        container.addSubview(content)
        content.addSubview(label)
        content.addSubview(iconImageView)
        content.constrainToCenter()
        iconImageView.constrainLeadingCorners()
        label.constrainTrailingCorners()
        iconImageView.constrain([
            iconImageView.constraint(toLeading: label, constant: -C.padding[1]) ])
        imageView = iconImageView
    }

    private func setupLabelOnly() {
        container.addSubview(label)
        label.constrain(toSuperviewEdges: UIEdgeInsets(top: C.padding[1], left: C.padding[1], bottom: -C.padding[1], right: -C.padding[1]))
    }

    private func setColors() {
        switch type {
        case .primary:
            container.backgroundColor = .darkGray
            label.textColor = .primaryText
            container.layer.borderColor = nil
            container.layer.borderWidth = 0.0
            shadowView.layer.shadowColor = UIColor.darkGray.cgColor
            shadowView.layer.shadowOpacity = 0.3
            imageView?.tintColor = .white
        case .secondary:
            container.backgroundColor = .darkGray
            label.textColor = .white
            container.layer.borderColor = UIColor.darkGray.cgColor
            container.layer.borderWidth = 1.0
            shadowView.layer.shadowColor = UIColor.darkGray.cgColor
            shadowView.layer.shadowOpacity = 0.15
            imageView?.tintColor = .darkText
        case .tertiary:
            imageView?.tintColor = .whiteTint
            label.textColor = .whiteTint
            container.layer.borderColor = nil
            container.layer.borderWidth = 0.0
        case .blackTransparent:
            container.backgroundColor = .clear
            label.textColor = .darkText
            container.layer.borderColor = UIColor.darkText.cgColor
            container.layer.borderWidth = 1.0
            imageView?.tintColor = .grayTextTint
            shadowView.isHidden = true
        case .search:
            label.font = UIFont.customBody(size: 13.0)
            container.backgroundColor = .white
            label.textColor = .black
            container.layer.borderColor = UIColor.secondaryBorder.cgColor
            container.layer.borderWidth = 1.0
            shadowView.layer.shadowColor = UIColor.black.cgColor
            shadowView.layer.shadowOpacity = 0.15
            imageView?.tintColor = .grayTextTint
        }
    }
    
    private func setNewColors() {
        switch type {
        case .primary:
            container.backgroundColor = .black
            label.textColor = .primaryText
            container.layer.borderColor = nil
            container.layer.borderWidth = 0.0
            shadowView.layer.shadowColor = UIColor.black.cgColor
            shadowView.layer.shadowOpacity = 0.3
            imageView?.tintColor = .white
        case .secondary:
            container.backgroundColor = .black
            label.textColor = .white
            container.layer.borderColor = UIColor.black.cgColor
            container.layer.borderWidth = 1.0
            shadowView.layer.shadowColor = UIColor.black.cgColor
            shadowView.layer.shadowOpacity = 0.15
            imageView?.tintColor = .darkText
        case .tertiary:
            container.backgroundColor = backColor
            imageView?.tintColor = imageColor
            label.textColor = .whiteTint
            container.layer.borderColor = nil
            container.layer.borderWidth = 0.0
        case .blackTransparent:
            container.backgroundColor = .clear
            label.textColor = .darkText
            container.layer.borderColor = UIColor.darkText.cgColor
            container.layer.borderWidth = 1.0
            imageView?.tintColor = .grayTextTint
            shadowView.isHidden = true
        case .search:
            label.font = UIFont.customBody(size: 13.0)
            container.backgroundColor = .white
            label.textColor = .black
            container.layer.borderColor = UIColor.secondaryBorder.cgColor
            container.layer.borderWidth = 1.0
            shadowView.layer.shadowColor = UIColor.black.cgColor
            shadowView.layer.shadowOpacity = 0.15
            imageView?.tintColor = .grayTextTint
        }
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden || isUserInteractionEnabled else { return nil }
        let deltaX = max(minTargetSize - bounds.width, 0)
        let deltaY = max(minTargetSize - bounds.height, 0)
        let hitFrame = bounds.insetBy(dx: -deltaX/2.0, dy: -deltaY/2.0)
        return hitFrame.contains(point) ? self : nil
    }

    @objc private func touchUpInside() {
        isSelected = !isSelected
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
