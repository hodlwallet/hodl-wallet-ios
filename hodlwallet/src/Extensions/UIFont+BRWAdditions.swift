//
//  UIFont+BRWAdditions.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-10-27.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

extension UIFont {
    static var header: UIFont {
        guard let font = UIFont(name: "Electrolize-Regular", size: 17.0) else { return UIFont.preferredFont(forTextStyle: .headline) }
        return font
    }
    static func customBold(size: CGFloat) -> UIFont {
        guard let font = UIFont(name: "Electrolize-Regular", size: size) else { return UIFont.preferredFont(forTextStyle: .headline) }
        return font
    }
    static func customBody(size: CGFloat) -> UIFont {
        guard let font = UIFont(name: "Electrolize-Regular", size: size) else { return UIFont.preferredFont(forTextStyle: .subheadline) }
        return font
    }
    static func customMedium(size: CGFloat) -> UIFont {
        guard let font = UIFont(name: "Electrolize-Regular", size: size) else { return UIFont.preferredFont(forTextStyle: .body) }
        return font
    }

    static var regularAttributes: [NSAttributedStringKey: Any] {
        return [
            NSAttributedStringKey.font: UIFont.customBody(size: 14.0),
            NSAttributedStringKey.foregroundColor: UIColor.gradientStart
        ]
    }
    
    static var sentAttributes: [NSAttributedStringKey: Any] {
        return [
            NSAttributedStringKey.font: UIFont.customBody(size: 14.0),
            NSAttributedStringKey.foregroundColor: UIColor.grayTextTint
        ]
    }
    
    static var movedAttributes: [NSAttributedStringKey: Any] {
        return [
            NSAttributedStringKey.font: UIFont.customBody(size: 14.0),
            NSAttributedStringKey.foregroundColor: UIColor.whiteTint
        ]
    }

    static var boldAttributes: [NSAttributedStringKey: Any] {
        return [
            NSAttributedStringKey.font: UIFont.customBold(size: 14.0),
            NSAttributedStringKey.foregroundColor: UIColor.gradientStart
        ]
    }
}
