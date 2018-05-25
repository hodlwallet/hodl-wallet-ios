//
//  MenuButton.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-11-30.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

class MenuButton : UIControl {

    //MARK: - Public
    let type: MenuButtonType

    init(type: MenuButtonType) {
        self.type = type
        super.init(frame: .zero)
        setupViews()
    }

    //MARK: - Private
    private let label = UILabel.init(font: .customBody(size: 16.0))
    private let image = UIImageView()
    private let border = UIView()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = .secondaryGrayText
            } else {
                backgroundColor = .grayBackground
            }
        }
    }

    private func setupViews() {
        addSubview(label)
        addSubview(border)

        label.constrain([
            label.constraint(.centerY, toView: self, constant: 0.0),
            label.constraint(.centerX, toView: self, constant: 0.0) ])
        border.constrainBottomCorners(sidePadding: 0, bottomPadding: 0)
        border.constrain([
            border.constraint(.height, constant: 1.0) ])

        label.text = type.title
        label.textColor = .white
        border.backgroundColor = .secondaryGrayText
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
