//
//  FeeSelector.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-07-20.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

enum Fee {
    case fastest
    case regular
    case economy
    case custom
}

class FeeSelector : UIView {

    init(store: Store) {
        self.store = store
        super.init(frame: .zero)
        addConstraints()
        setupViews()
    }
    
    var feeString: NSAttributedString? {
        didSet {
            updateSelector()
        }
    }

    var didUpdateFee: ((Fee) -> Void)?

    func removeIntrinsicSize() {
        guard let bottomConstraint = bottomConstraint else { return }
        NSLayoutConstraint.deactivate([bottomConstraint])
    }

    func addIntrinsicSize() {
        guard let bottomConstraint = bottomConstraint else { return }
        NSLayoutConstraint.activate([bottomConstraint])
    }
    
    let advanced = UIButton(type: .system)
    
    private let store: Store
    private let feeHeader = UILabel(font: .customBody(size: 16.0), color: .whiteTint)
    private let deliveryHeader = UILabel(font: .customBody(size: 16.0), color: .whiteTint)
    private let feeBody = UILabel(font: .customMedium(size: 15.0), color: .grayTextTint)
    private let deliveryBody = UILabel(font: .customMedium(size: 16.0), color: .grayTextTint)
    private let economy = UILabel.wrapping(font: .customBody(size: 16.0), color: .whiteTint)
    private let normal = UILabel.wrapping(font: .customBody(size: 16.0), color: .whiteTint)
    private let fastest = UILabel.wrapping(font: .customBody(size: 16.0), color: .whiteTint)
    private let control = UISlider()
    private let customBorder = UIView(color: .secondaryGrayText)
    private var bottomConstraint: NSLayoutConstraint?
    
    private func addConstraints() {
        addSubview(control)
        addSubview(feeHeader)
        addSubview(deliveryHeader)
        addSubview(feeBody)
        addSubview(deliveryBody)
        addSubview(economy)
        addSubview(normal)
        addSubview(fastest)
        addSubview(advanced)
        addSubview(customBorder)
        
        feeHeader.constrain([
            feeHeader.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            feeHeader.topAnchor.constraint(equalTo: topAnchor) ])
        feeHeader.text = S.FeeSelector.networkFee
        deliveryHeader.constrain([
            deliveryHeader.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            deliveryHeader.topAnchor.constraint(equalTo: feeHeader.topAnchor) ])
        deliveryHeader.text = S.FeeSelector.estDelivery
        
        feeBody.constrain([
            feeBody.leadingAnchor.constraint(equalTo: feeHeader.leadingAnchor),
            feeBody.topAnchor.constraint(equalTo: feeHeader.bottomAnchor, constant: C.padding[1]) ])
        feeBody.text = String(format: S.FeeSelector.satByte, "\(store.state.fees.regular.sats / C.byteShift)")
        deliveryBody.constrain([
            deliveryBody.trailingAnchor.constraint(equalTo: deliveryHeader.trailingAnchor),
            deliveryBody.topAnchor.constraint(equalTo: deliveryHeader.bottomAnchor, constant: C.padding[1])])
        
        bottomConstraint = advanced.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1])
        
        economy.constrain([
            economy.leadingAnchor.constraint(equalTo: feeHeader.leadingAnchor),
            economy.topAnchor.constraint(equalTo: feeBody.bottomAnchor, constant: C.padding[1])])
        economy.text = S.FeeSelector.economy
        normal.constrain([
            normal.centerXAnchor.constraint(equalTo: centerXAnchor),
            normal.topAnchor.constraint(equalTo: economy.topAnchor) ])
        normal.text = S.FeeSelector.normal
        fastest.constrain([
            fastest.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            fastest.topAnchor.constraint(equalTo: economy.topAnchor) ])
        fastest.text = S.FeeSelector.fastest
        
        advanced.constrain([
            advanced.leadingAnchor.constraint(equalTo: feeHeader.leadingAnchor),
            advanced.topAnchor.constraint(equalTo: customBorder.bottomAnchor, constant: 4.0) ])
        advanced.setTitle(S.FeeSelector.customFee, for: .normal)
        advanced.setTitleColor(.grayTextTint, for: .normal)
        advanced.titleLabel?.font = .customMedium(size: 14.0)
        
        customBorder.constrain([
            customBorder.leadingAnchor.constraint(equalTo: leadingAnchor),
            customBorder.topAnchor.constraint(equalTo: control.bottomAnchor, constant: C.padding[1]),
            customBorder.trailingAnchor.constraint(equalTo: trailingAnchor),
            customBorder.heightAnchor.constraint(equalToConstant: 1.0) ])
        
        deliveryBody.text = store.state.fees.regular.time as String
        
        control.constrain([
            control.leadingAnchor.constraint(equalTo: economy.leadingAnchor),
            control.topAnchor.constraint(equalTo: economy.bottomAnchor, constant: 5.0),
            control.widthAnchor.constraint(equalTo: widthAnchor, constant: -C.padding[4]) ])
    }
    
    private func setupViews() {
        control.minimumValue = 1
        control.maximumValue = 3
        control.minimumTrackTintColor = .gradientStart
        control.minimumValueImage = UIImage(named: "Minus")
        control.maximumValueImage = UIImage(named: "Plus")
        control.setThumbImage(UIImage(named: "sliderCircle"), for: .normal)
        control.isContinuous = false
        
        control.valueChanged = strongify(self) { myself in
            // have the tick in 3 positions
            myself.control.setValue(floorf(myself.control.value + 0.5),animated: true)
            
            if myself.control.value >= 3 {
                myself.didUpdateFee?(.fastest)
                myself.deliveryBody.text = myself.store.state.fees.fastest.time as String
                if myself.feeBody.text!.isEmpty {
                    myself.feeBody.text = String(format: S.FeeSelector.satByte,
                                                 "\(myself.store.state.fees.fastest.sats / C.byteShift)")
                }
            } else if myself.control.value >= 2 {
                myself.didUpdateFee?(.regular)
                myself.deliveryBody.text = myself.store.state.fees.regular.time as String
                if myself.feeBody.text!.isEmpty {
                    myself.feeBody.text = String(format: S.FeeSelector.satByte,
                                                 "\(myself.store.state.fees.regular.sats / C.byteShift)")
                }
            } else {
                myself.didUpdateFee?(.economy)
                myself.deliveryBody.text = myself.store.state.fees.economy.time as String
                if myself.feeBody.text!.isEmpty {
                    myself.feeBody.text = String(format: S.FeeSelector.satByte,
                                                 "\(myself.store.state.fees.economy.sats / C.byteShift)")
                }
            }
        }

        // control.selectedSegmentIndex = 0
        clipsToBounds = true

        control.setValue(2, animated: true)
    }
    
    func updateSelector() {
        feeBody.attributedText = feeString
        if feeBody.text!.isEmpty {
            if control.value >= 3 {
                feeBody.text = String(format: S.FeeSelector.satByte,
                                      "\(store.state.fees.fastest.sats / C.byteShift)")
            }
            else if control.value >= 2 {
                feeBody.text = String(format: S.FeeSelector.satByte,
                                      "\(store.state.fees.regular.sats / C.byteShift)")
            }
            else {
                feeBody.text = String(format: S.FeeSelector.satByte,
                                      "\(store.state.fees.economy.sats / C.byteShift)")
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
