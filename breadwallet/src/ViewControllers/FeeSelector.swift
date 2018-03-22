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
    private let header = UILabel(font: .customMedium(size: 16.0), color: .whiteTint)
    private let subheader = UILabel(font: .customBody(size: 14.0), color: .grayTextTint)
    private let warning = UILabel.wrapping(font: .customBody(size: 14.0), color: .grayTextTint)
    private let control = UISlider()
    private var bottomConstraint: NSLayoutConstraint?

    private func setupViews() {
        addSubview(control)
        addSubview(header)
        addSubview(subheader)
        addSubview(warning)

        header.constrain([
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: C.padding[2]),
            header.topAnchor.constraint(equalTo: topAnchor, constant: C.padding[1]) ])
        subheader.constrain([
            subheader.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            subheader.topAnchor.constraint(equalTo: header.bottomAnchor) ])

        bottomConstraint = warning.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -C.padding[1])
        warning.constrain([
            warning.leadingAnchor.constraint(equalTo: subheader.leadingAnchor),
            warning.topAnchor.constraint(equalTo: control.bottomAnchor, constant: 4.0),
            warning.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]) ])
        header.text = S.FeeSelector.title
        subheader.text = String(format: S.FeeSelector.estimatedDelivery, S.FeeSelector.regularTime)
        control.constrain([
            control.leadingAnchor.constraint(equalTo: warning.leadingAnchor),
            control.topAnchor.constraint(equalTo: subheader.bottomAnchor, constant: 4.0),
            control.widthAnchor.constraint(equalTo: widthAnchor, constant: -C.padding[4]) ])
        
        control.minimumValue = Float(store.state.fees.economy.sats)
        control.maximumValue = Float(store.state.fees.fastest.sats)
        
        // Warning text -> sat/byte (localization)
        var hours = Int(0)
        control.valueChanged = strongify(self) { myself in
            if myself.control.value >= Float(myself.store.state.fees.fastest.sats) {
                myself.didUpdateFee?(.fastest)
                
                if myself.store.state.fees.fastest.time / 60 < 2 {
                    myself.subheader.text = String(format: S.FeeSelector.minuteTime,
                        "\(myself.store.state.fees.fastest.time)")
                } else {
                    hours = myself.store.state.fees.fastest.time / 60
                    myself.subheader.text = String(format: S.FeeSelector.hourTime, "\(hours)")
                }
                
                myself.warning.text = String(format: S.FeeSelector.satsByte, "\(myself.store.state.fees.fastest.sats / 1000)")
            } else if myself.control.value >= Float(myself.store.state.fees.regular.sats)
                && myself.control.value < Float(myself.store.state.fees.fastest.sats) {
                let newFees = Fees(fastest: myself.store.state.fees.fastest,
                                   regular: myself.store.state.fees.regular,
                                   economy: myself.store.state.fees.economy,
                                   current: UInt64(myself.control.value))
                myself.store.perform(action: UpdateFees.set(newFees))
                myself.didUpdateFee?(.regular)
                
                if myself.store.state.fees.regular.time / 60 < 2 {
                    myself.subheader.text = String(format: S.FeeSelector.minuteTime,
                        "\(myself.store.state.fees.regular.time)")
                } else {
                    hours = myself.store.state.fees.regular.time / 60
                    myself.subheader.text = String(format: S.FeeSelector.hourTime, "\(hours)")
                }
                
                myself.warning.text = String(format: S.FeeSelector.satsByte, "\(Int(myself.control.value) / 1000)")
            } else if myself.control.value < Float(myself.store.state.fees.regular.sats) {
                let newFees = Fees(fastest: myself.store.state.fees.fastest,
                                   regular: myself.store.state.fees.regular,
                                   economy: myself.store.state.fees.economy,
                                   current: UInt64(myself.control.value))
                myself.store.perform(action: UpdateFees.set(newFees))
                myself.didUpdateFee?(.economy)
                
                if myself.store.state.fees.economy.time / 60 < 2 {
                    myself.subheader.text = String(format: S.FeeSelector.minuteTime,
                        "\(myself.store.state.fees.economy.time)")
                } else {
                    hours = myself.store.state.fees.economy.time / 60
                    myself.subheader.text = String(format: S.FeeSelector.hourTime, "\(hours)")
                }
                
                myself.warning.text = String(format: S.FeeSelector.satsByte, "\(Int(myself.control.value) / 1000)")
            }
        }

        // control.selectedSegmentIndex = 0
        clipsToBounds = true

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
