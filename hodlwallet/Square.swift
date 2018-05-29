//
//  Square.swift
//  hodlwallet
//
//  Created by Igor on 5/14/18.
//

import UIKit

class Square: UIView {
    
    private let color: UIColor
    
    static let defaultSize: CGFloat = 64.0
    
    init(color: UIColor) {
        self.color = color
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.addRect(rect)
        context.setFillColor(color.cgColor)
        context.fillPath()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
