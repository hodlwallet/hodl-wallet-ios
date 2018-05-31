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
    private let feeBody = UILabel(font: .customMedium(size: 16.0), color: .grayTextTint)
    private let deliveryBody = UILabel(font: .customMedium(size: 16.0), color: .grayTextTint)
    private let slow = UILabel.wrapping(font: .customBody(size: 16.0), color: .whiteTint)
    private let normal = UILabel.wrapping(font: .customBody(size: 16.0), color: .whiteTint)
    private let fastest = UILabel.wrapping(font: .customBody(size: 16.0), color: .whiteTint)
    private let control = UISlider()
    private var bottomConstraint: NSLayoutConstraint?
    
    private func addConstraints() {
        addSubview(control)
        addSubview(feeHeader)
        addSubview(deliveryHeader)
        addSubview(feeBody)
        addSubview(deliveryBody)
        addSubview(slow)
        addSubview(normal)
        addSubview(fastest)
        addSubview(advanced)
        
        feeHeader.constrain([
            feeHeader.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            feeHeader.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[1]) ])
        feeHeader.text = S.FeeSelector.networkFee
        deliveryHeader.constrain([
            deliveryHeader.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            deliveryHeader.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[1]) ])
        deliveryHeader.text = S.FeeSelector.estDelivery
        
        feeBody.constrain([
            feeBody.leadingAnchor.constraint(equalTo: feeHeader.leadingAnchor),
            feeBody.topAnchor.constraint(equalTo: feeHeader.bottomAnchor, constant: C.padding[1]) ])
        feeBody.text = String(format: S.FeeSelector.satByte, "\(store.state.fees.economy.sats / 1000)")
        deliveryBody.constrain([
            deliveryBody.trailingAnchor.constraint(equalTo: deliveryHeader.trailingAnchor),
            deliveryBody.topAnchor.constraint(equalTo: deliveryHeader.bottomAnchor, constant: C.padding[1])])
        
        bottomConstraint = advanced.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1])
        
        slow.constrain([
            slow.leadingAnchor.constraint(equalTo: feeHeader.leadingAnchor),
            slow.topAnchor.constraint(equalTo: deliveryBody.bottomAnchor, constant: C.padding[1])])
        slow.text = S.FeeSelector.slow
        normal.constrain([
            normal.centerXAnchor.constraint(equalTo: centerXAnchor),
            normal.topAnchor.constraint(equalTo: slow.topAnchor) ])
        normal.text = S.FeeSelector.normal
        fastest.constrain([
            fastest.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            fastest.topAnchor.constraint(equalTo: slow.topAnchor) ])
        fastest.text = S.FeeSelector.fastest
        
        advanced.constrain([
            advanced.leadingAnchor.constraint(equalTo: feeHeader.leadingAnchor),
            advanced.topAnchor.constraint(equalTo: control.bottomAnchor, constant: 4.0) ])
        advanced.setTitle(S.FeeSelector.advanced, for: .normal)
        advanced.setTitleColor(.gradientStart, for: .normal)
        advanced.titleLabel?.font = .customMedium(size: 12.0)
        
        deliveryBody.text = store.state.fees.economy.time as String
        
        control.constrain([
            control.leadingAnchor.constraint(equalTo: slow.leadingAnchor),
            control.topAnchor.constraint(equalTo: slow.bottomAnchor, constant: 5.0),
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
                                                 "\(myself.store.state.fees.fastest.sats / 1000)")
                }
            } else if myself.control.value >= 2 {
                myself.didUpdateFee?(.regular)
                myself.deliveryBody.text = myself.store.state.fees.regular.time as String
                if myself.feeBody.text!.isEmpty {
                    myself.feeBody.text = String(format: S.FeeSelector.satByte,
                                                 "\(myself.store.state.fees.regular.sats / 1000)")
                }
            } else {
                myself.didUpdateFee?(.economy)
                myself.deliveryBody.text = myself.store.state.fees.economy.time as String
                if myself.feeBody.text!.isEmpty {
                    myself.feeBody.text = String(format: S.FeeSelector.satByte,
                                                 "\(myself.store.state.fees.economy.sats / 1000)")
                }
            }
        }

        // control.selectedSegmentIndex = 0
        clipsToBounds = true

    }
    
    func updateSelector() {
        feeBody.attributedText = feeString
        if feeBody.text!.isEmpty {
            if control.value >= 3 {
                feeBody.text = String(format: S.FeeSelector.satByte,
                                      "\(store.state.fees.fastest.sats / 1000)")
            }
            else if control.value >= 2 {
                feeBody.text = String(format: S.FeeSelector.satByte,
                                      "\(store.state.fees.regular.sats / 1000)")
            }
            else {
                feeBody.text = String(format: S.FeeSelector.satByte,
                                      "\(store.state.fees.economy.sats / 1000)")
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
