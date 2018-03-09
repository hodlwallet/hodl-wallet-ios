//
//  FeeSelector.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-07-20.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

enum Fee {
    case regular
    case economy
    case current
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
    private let warning = UILabel.wrapping(font: .customBody(size: 14.0), color: .red)
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
        
        control.minimumValue = Float(store.state.fees.economy)
        control.maximumValue = Float(store.state.fees.regular)
        
        control.valueChanged = strongify(self) { myself in
            if myself.control.value == Float(myself.store.state.fees.regular) {
                myself.didUpdateFee?(.regular)
                myself.subheader.text = String(format: S.FeeSelector.estimatedDelivery, S.FeeSelector.regularTime)
                myself.warning.text = ""
            } else if myself.control.value == Float(myself.store.state.fees.economy) {
                myself.didUpdateFee?(.economy)
                myself.subheader.text = String(format: S.FeeSelector.estimatedDelivery, S.FeeSelector.economyTime)
                myself.warning.text = S.FeeSelector.economyWarning
            } else {
                let newFees = Fees(regular: myself.store.state.fees.regular, economy: myself.store.state.fees.economy, current: UInt64(myself.control.value))
                myself.store.perform(action: UpdateFees.set(newFees))
                myself.didUpdateFee?(.current)
            }
        }

        // control.selectedSegmentIndex = 0
        clipsToBounds = true

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
