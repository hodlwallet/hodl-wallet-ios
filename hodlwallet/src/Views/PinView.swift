//
//  PinView.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-10-28.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

enum PinViewStyle {
    case create
    case login
}

class PinView : UIView {

    //MARK: - Public
    var itemSize: CGFloat {
        switch style {
        case .create:
            return 24.0
        case .login:
            return 16.0
        }
    }
    var width: CGFloat {
        return (itemSize + C.padding[1]) * CGFloat(length)
    }
    let shakeDuration: CFTimeInterval = 0.6
    fileprivate var shakeCompletion: (() -> Void)?

    init(style: PinViewStyle, length: Int) {
        self.style = style
        self.length = length
        switch style {
        case .create:
            unFilled = (0...(length-1)).map { _ in Square(color: .borderGray) }
        case .login:
            unFilled = (0...(length-1)).map { _ in Square(color: .white) }
        }
        filled = (0...(length-1)).map { _ in Square(color: .gradientEnd) }
        super.init(frame: CGRect())
        setupSubviews()
    }

    func fill(_ number: Int) {
        filled.enumerated().forEach { index, square in
            square.isHidden = index > number-1
        }
    }

    func shake(completion: (() -> Void)? = nil) {
        shakeCompletion = completion
        let translation = CAKeyframeAnimation(keyPath: "transform.translation.x");
        translation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        translation.values = [-5, 5, -5, 5, -3, 3, -2, 2, 0]

        let rotation = CAKeyframeAnimation(keyPath: "transform.rotation.y");
        rotation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)

        rotation.values = [-5, 5, -5, 5, -3, 3, -2, 2, 0].map {
            self.toRadian(value: $0)
        }
        let shakeGroup: CAAnimationGroup = CAAnimationGroup()
        shakeGroup.animations = [translation, rotation]
        shakeGroup.duration = shakeDuration
        shakeGroup.delegate = self
        self.layer.add(shakeGroup, forKey: "shakeIt")
    }

    //MARK: - Private
    private let unFilled: [Square]
    private var filled: [Square]
    private let style: PinViewStyle
    private let length: Int

    private func toRadian(value: Int) -> CGFloat {
        return CGFloat(Double(value) / 180.0 * .pi)
    }

    private func setupSubviews() {
        addSquareContraints(unFilled)
        addSquareContraints(filled)
        filled.forEach { $0.isHidden = true }
    }

    private func addSquareContraints(_ squares: [Square]) {
        squares.enumerated().forEach { index, square in
            addSubview(square)
            let leadingConstraint: NSLayoutConstraint?
            if index == 0 {
                leadingConstraint = square.constraint(.leading, toView: self, constant: 0.0)
            } else {
                leadingConstraint = NSLayoutConstraint(item: square, attribute: .leading, relatedBy: .equal, toItem: squares[index - 1], attribute: .trailing, multiplier: 1.0, constant: 8.0)
            }
            square.constrain([
                square.constraint(.width, constant: itemSize),
                square.constraint(.height, constant: itemSize),
                square.constraint(.centerY, toView: self, constant: nil),
                leadingConstraint ])
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PinView : CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        shakeCompletion?()
    }
}
