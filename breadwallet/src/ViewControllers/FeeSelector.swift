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
}

class FeeSelector : UIView {

    init(store: Store) {
        self.store = store
        super.init(frame: .zero)
        setupViews()
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

    private let store: Store
    private let feeHeader = UILabel(font: .customBody(size: 16.0), color: .whiteTint)
    private let deliveryHeader = UILabel(font: .customBody(size: 16.0), color: .whiteTint)
    private let feeBody = UILabel(font: .customMedium(size: 24.0), color: .whiteTint)
    private let deliveryBody = UILabel(font: .customMedium(size: 24.0), color: .whiteTint)
    private let warning = UILabel.wrapping(font: .customBody(size: 16.0), color: .red)
    private let slow = UILabel.wrapping(font: .customBody(size: 16.0), color: .whiteTint)
    private let normal = UILabel.wrapping(font: .customBody(size: 16.0), color: .whiteTint)
    private let fastest = UILabel.wrapping(font: .customBody(size: 16.0), color: .whiteTint)
    private let control = UISlider()
    private var bottomConstraint: NSLayoutConstraint?
    
    private func setupViews() {
        addSubview(control)
        addSubview(feeHeader)
        addSubview(deliveryHeader)
        addSubview(feeBody)
        addSubview(deliveryBody)
        addSubview(slow)
        addSubview(normal)
        addSubview(fastest)
        addSubview(warning)
        
        feeHeader.constrain([
            feeHeader.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            feeHeader.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[1]) ])
        feeHeader.text = S.FeeSelector.networkFee
        deliveryHeader.constrain([
            deliveryHeader.leadingAnchor.constraint(equalTo: feeHeader.trailingAnchor, constant: C.padding[7]),
            deliveryHeader.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[1]) ])
        deliveryHeader.text = S.FeeSelector.estDelivery
        
        feeBody.constrain([
            feeBody.leadingAnchor.constraint(equalTo: feeHeader.leadingAnchor),
            feeBody.topAnchor.constraint(equalTo: feeHeader.bottomAnchor, constant: C.padding[1]) ])
        feeBody.text = String(format: S.FeeSelector.satByte, "\(store.state.fees.economy.sats / 1000)")
        deliveryBody.constrain([
            deliveryBody.leadingAnchor.constraint(equalTo: deliveryHeader.leadingAnchor),
            deliveryBody.topAnchor.constraint(equalTo: deliveryHeader.bottomAnchor, constant: C.padding[1])])
        
        bottomConstraint = warning.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[2])
        
        slow.constrain([
            slow.leadingAnchor.constraint(equalTo: feeHeader.leadingAnchor),
            slow.topAnchor.constraint(equalTo: deliveryBody.bottomAnchor, constant: C.padding[2])])
        slow.text = S.FeeSelector.slow
        normal.constrain([
            normal.centerXAnchor.constraint(equalTo: centerXAnchor, constant: -C.padding[1]),
            normal.topAnchor.constraint(equalTo: deliveryBody.bottomAnchor, constant: C.padding[2])])
        normal.text = S.FeeSelector.normal
        fastest.constrain([
            fastest.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            fastest.topAnchor.constraint(equalTo: deliveryBody.bottomAnchor, constant: C.padding[2])])
        fastest.text = S.FeeSelector.fastest
        
        warning.constrain([
            warning.leadingAnchor.constraint(equalTo: feeHeader.leadingAnchor),
            warning.topAnchor.constraint(equalTo: control.bottomAnchor, constant: 4.0),
            warning.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]) ])
        warning.text = ""
        
        var hours = Int(0)
        if store.state.fees.economy.time / 60 < 2 {
            deliveryBody.text = String(format: S.FeeSelector.minuteTime,
                                           "\(store.state.fees.economy.time)")
        } else {
            hours = store.state.fees.economy.time / 60
            deliveryBody.text = String(format: S.FeeSelector.hourTime, "\(hours)")
        }
        control.constrain([
            control.leadingAnchor.constraint(equalTo: slow.leadingAnchor),
            control.topAnchor.constraint(equalTo: slow.bottomAnchor, constant: 4.0),
            control.widthAnchor.constraint(equalTo: widthAnchor, constant: -C.padding[4]) ])
        
        control.minimumValue = Float(store.state.fees.economy.sats)
        control.maximumValue = Float(store.state.fees.fastest.sats)
        control.minimumTrackTintColor = .gradientStart
        control.minimumValueImage = UIImage(named: "Minus")
        control.maximumValueImage = UIImage(named: "Plus")
        
        control.valueChanged = strongify(self) { myself in
            if myself.control.value >= Float(myself.store.state.fees.fastest.sats) {
                myself.didUpdateFee?(.fastest)
                
                if myself.store.state.fees.fastest.time / 60 < 2 {
                    myself.deliveryBody.text = String(format: S.FeeSelector.minuteTime,
                        "\(myself.store.state.fees.fastest.time)")
                } else {
                    hours = myself.store.state.fees.fastest.time / 60
                    myself.deliveryBody.text = String(format: S.FeeSelector.hourTime, "\(hours)")
                }
                myself.feeBody.text = String(format: S.FeeSelector.satByte, "\(myself.store.state.fees.fastest.sats / 1000)")
                myself.warning.text = ""
            } else if myself.control.value >= Float(myself.store.state.fees.regular.sats)
                && myself.control.value < Float(myself.store.state.fees.fastest.sats) {
                let newFees = Fees(fastest: myself.store.state.fees.fastest,
                                   regular: myself.store.state.fees.regular,
                                   economy: myself.store.state.fees.economy,
                                   current: UInt64(myself.control.value))
                myself.store.perform(action: UpdateFees.set(newFees))
                myself.didUpdateFee?(.regular)
                
                if myself.store.state.fees.regular.time / 60 < 2 {
                    myself.deliveryBody.text = String(format: S.FeeSelector.minuteTime,
                        "\(myself.store.state.fees.regular.time)")
                } else {
                    hours = myself.store.state.fees.regular.time / 60
                    myself.deliveryBody.text = String(format: S.FeeSelector.hourTime, "\(hours)")
                }
                
                myself.feeBody.text = String(format: S.FeeSelector.satByte, "\(Int(myself.control.value) / 1000)")
                myself.warning.text = ""
            } else if myself.control.value < Float(myself.store.state.fees.regular.sats) {
                let newFees = Fees(fastest: myself.store.state.fees.fastest,
                                   regular: myself.store.state.fees.regular,
                                   economy: myself.store.state.fees.economy,
                                   current: UInt64(myself.control.value))
                myself.store.perform(action: UpdateFees.set(newFees))
                myself.didUpdateFee?(.economy)
                
                if myself.store.state.fees.economy.time / 60 < 2 {
                    myself.deliveryBody.text = String(format: S.FeeSelector.minuteTime,
                        "\(myself.store.state.fees.economy.time)")
                } else {
                    hours = myself.store.state.fees.economy.time / 60
                    myself.deliveryBody.text = String(format: S.FeeSelector.hourTime, "\(hours)")
                }
                
                myself.feeBody.text = String(format: S.FeeSelector.satByte, "\(Int(myself.control.value) / 1000)")
                myself.warning.text = S.FeeSelector.economyWarning
            }
        }

        // control.selectedSegmentIndex = 0
        clipsToBounds = true

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
