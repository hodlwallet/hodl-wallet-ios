//
//  DarkNumberPad.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-03-16.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

class DarkNumberPad : GenericPinPadCell {

    override func setAppearance() {

        if text == "0" {
            topLabel.isHidden = true
            centerLabel.isHidden = false
        } else {
            topLabel.isHidden = false
            centerLabel.isHidden = true
        }

        if isHighlighted {
            backgroundColor = .secondaryGrayText
            topLabel.textColor = .darkText
            centerLabel.textColor = .darkText
            sublabel.textColor = .darkText
        } else {
            if text == "" || text == deleteKeyIdentifier {
                backgroundColor = .darkGray
                imageView.image = imageView.image?.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = .gradientStart
            } else {
                backgroundColor = .darkGray
                topLabel.textColor = .whiteTint
                centerLabel.textColor = .whiteTint
                sublabel.textColor = .whiteTint
            }
        }
    }

    override func setSublabel() {
        guard let text = self.text else { return }
        if sublabels[text] != nil {
            sublabel.text = sublabels[text]
        }
    }
}
