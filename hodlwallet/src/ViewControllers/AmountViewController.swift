//
//  AmountViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-05-19.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

private let currencyHeight: CGFloat = 80.0
private let feeHeight: CGFloat = 130.0

class AmountViewController : UIViewController, Trackable {

    init(store: Store, isPinPadExpandedAtLaunch: Bool, isRequesting: Bool = false) {
        self.store = store
        self.isPinPadExpandedAtLaunch = isPinPadExpandedAtLaunch
        self.isRequesting = isRequesting
        if let rate = store.state.currentRate, store.state.isBtcSwapped {
            self.currency.text = "\(rate.code) (\(rate.currencySymbol))"
        } else {
            self.currency.text = S.Symbols.currencyButtonTitle(maxDigits: store.state.maxDigits)
        }
        self.feeSelector = FeeSelector(store: store)
        self.advancedButton = self.feeSelector.advanced
        self.pinPad = PinPadViewController(style: .white, keyboardType: .decimalPad, maxDigits: store.state.maxDigits)
        super.init(nibName: nil, bundle: nil)
    }

    var balanceTextForAmount: ((Satoshis?, Rate?) -> (NSAttributedString?, NSAttributedString?)?)?
    var didUpdateAmount: ((Satoshis?) -> Void)?
    var didChangeFirstResponder: ((Bool) -> Void)?

    var currentOutput: String {
        return amountLabel.text ?? ""
    }
    var selectedRate: Rate? {
        didSet {
            fullRefresh()
        }
    }
    var didUpdateFee: ((Fee) -> Void)? {
        didSet {
            feeSelector.didUpdateFee = didUpdateFee
        }
    }
    func forceUpdateAmount(amount: Satoshis) {
        self.amount = amount
        fullRefresh()
    }

    func expandPinPad() {
        if pinPadHeight?.constant == 0.0 {
            togglePinPad()
        }
    }
    
    let advancedButton: UIButton

    private let store: Store
    private let isPinPadExpandedAtLaunch: Bool
    private let isRequesting: Bool
    var minimumFractionDigits = 0
    private var hasTrailingDecimal = false
    private var pinPadHeight: NSLayoutConstraint?
    private var feeSelectorHeight: NSLayoutConstraint?
    private var feeSelectorTop: NSLayoutConstraint?
    private let amountTitle = UILabel(font: .customBody(size: 16.0), color: .whiteTint)
    private let placeholder = UILabel(font: .customBody(size: 26.0), color: .gradientStart)
    private let amountLabel = UILabel(font: .customBody(size: 26.0), color: .gradientStart)
    private let pinPad: PinPadViewController
    private let currencyToggle = ShadowButton(title: "", type: .tertiary, image: #imageLiteral(resourceName: "CurrencySwitch"), imageColor: .grayTextTint, backColor: .grayBackground)
    private let currency = UILabel(font: .customBody(size: 16.0), color: .gradientStart)
    private let border = UIView(color: .secondaryGrayText)
    private let bottomBorder = UIView(color: .secondaryGrayText)
    private let balanceBorder = UIView(color: .secondaryGrayText)
    private let customBorder = UIView(color: .secondaryGrayText)
    private let cursor = BlinkingView(blinkColor: C.defaultTintColor)
    private let balanceLabel = UILabel()
    private let feeLabel = UILabel()
    private let feeContainer = InViewAlert(type: .temporary)
    private let tapView = UIView()
    private let editFee = UIButton(type: .system)
    private let feeSelector: FeeSelector

    private var amount: Satoshis? {
        didSet {
            updateAmountLabel()
            updateBalanceLabel()
            didUpdateAmount?(amount)
        }
    }

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    private func addSubviews() {
        view.addSubview(amountLabel)
        view.addSubview(amountTitle)
        view.addSubview(placeholder)
        view.addSubview(currency)
        view.addSubview(currencyToggle)
        view.addSubview(feeContainer)
        view.addSubview(border)
        view.addSubview(cursor)
        view.addSubview(balanceLabel)
        view.addSubview(tapView)
        view.addSubview(bottomBorder)
        view.addSubview(balanceBorder)
        view.addSubview(customBorder)
    }

    private func addConstraints() {
        amountLabel.constrain([
            amountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            amountLabel.centerYAnchor.constraint(equalTo: currencyToggle.centerYAnchor) ])
        amountTitle.constrain([
            amountTitle.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor),
            amountTitle.topAnchor.constraint(equalTo: view.topAnchor, constant: C.padding[1]) ])
        placeholder.constrain([
            placeholder.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor, constant: 2.0),
            placeholder.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor) ])
        cursor.constrain([
            cursor.leadingAnchor.constraint(equalTo: amountLabel.trailingAnchor, constant: 2.0),
            cursor.heightAnchor.constraint(equalToConstant: 24.0),
            cursor.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor),
            cursor.widthAnchor.constraint(equalToConstant: 2.0) ])
        currencyToggle.constrain([
            currencyToggle.topAnchor.constraint(equalTo: amountTitle.bottomAnchor, constant: 20.0),
            currencyToggle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[3]) ])
        currency.constrain([
            currency.trailingAnchor.constraint(equalTo: currencyToggle.leadingAnchor, constant: -C.padding[4]),
            currency.centerYAnchor.constraint(equalTo: currencyToggle.centerYAnchor) ])
        feeSelectorHeight = feeContainer.heightAnchor.constraint(equalToConstant: 0.0)
        feeSelectorTop = feeContainer.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor)

        feeContainer.constrain([
            feeSelectorTop,
            feeSelectorHeight,
            feeContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            feeContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        feeContainer.arrowXLocation = C.padding[4]

        let borderTop = isRequesting ? border.topAnchor.constraint(equalTo: currencyToggle.bottomAnchor, constant: C.padding[2]) : border.topAnchor.constraint(equalTo: feeContainer.bottomAnchor)
        border.constrain([
            border.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            borderTop,
            border.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 1.0) ])
        
        let balanceBorderHeight = isRequesting ? balanceBorder.heightAnchor.constraint(equalToConstant: 0.0) : balanceBorder.heightAnchor.constraint(equalToConstant: 1.0)
        balanceBorder.constrain([
            balanceBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            balanceBorder.topAnchor.constraint(equalTo: placeholder.bottomAnchor, constant: 4.0),
            balanceBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            balanceBorderHeight ])
        
        balanceLabel.constrain([
            balanceLabel.leadingAnchor.constraint(equalTo: amountLabel.leadingAnchor),
            balanceLabel.topAnchor.constraint(equalTo: balanceBorder.bottomAnchor, constant: 4.0) ])
        pinPadHeight = pinPad.view.heightAnchor.constraint(equalToConstant: 0.0)
        addChildViewController(pinPad, layout: {
            pinPad.view.constrain([
                pinPad.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                pinPad.view.topAnchor.constraint(equalTo: border.bottomAnchor),
                pinPad.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                pinPad.view.bottomAnchor.constraint(equalTo: bottomBorder.topAnchor),
                pinPadHeight ])
        })
        bottomBorder.constrain([
            bottomBorder.topAnchor.constraint(greaterThanOrEqualTo: currencyToggle.bottomAnchor, constant: C.padding[2]),
            bottomBorder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBorder.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBorder.heightAnchor.constraint(equalToConstant: 1.0) ])

        tapView.constrain([
            tapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tapView.topAnchor.constraint(equalTo: view.topAnchor),
            tapView.trailingAnchor.constraint(equalTo: currencyToggle.leadingAnchor, constant: -8.0),
            tapView.bottomAnchor.constraint(equalTo: feeContainer.topAnchor) ])
        preventAmountOverflow()
    }

    private func setInitialData() {
        cursor.isHidden = true
        amountLabel.text = ""
        amountTitle.text = S.Send.amountLabel
        let placeholderAmount = DisplayAmount(amount: Satoshis(0), state: store.state, selectedRate: selectedRate, minimumFractionDigits: minimumFractionDigits)
        placeholder.text = placeholderAmount.description
        bottomBorder.isHidden = true
        if store.state.isBtcSwapped {
            if let rate = store.state.currentRate {
                selectedRate = rate
            }
        }
        pinPad.ouputDidUpdate = { [weak self] output in
            self?.handlePinPadUpdate(output: output)
        }
        currencyToggle.tap = strongify(self) { myself in
            myself.toggleCurrency()
        }
        let gr = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tapView.addGestureRecognizer(gr)
        tapView.isUserInteractionEnabled = true

        if isPinPadExpandedAtLaunch {
            didTap()
        }

        feeContainer.contentView = feeSelector
        if !isRequesting { toggleFeeSelector() }
    }

    private func toggleCurrency() {
        saveEvent("amount.swapCurrency")
        selectedRate = selectedRate == nil ? store.state.currentRate : nil
        
        updateCurrencyToggleTitle()
    }

    private func preventAmountOverflow() {
        amountLabel.constrain([
            amountLabel.trailingAnchor.constraint(lessThanOrEqualTo: currencyToggle.leadingAnchor, constant: -C.padding[2]) ])
        amountLabel.minimumScaleFactor = 0.5
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
    }

    private func handlePinPadUpdate(output: String) {
        var currencyDecimalSeparator = NumberFormatter().currencyDecimalSeparator ?? "."
        
        placeholder.isHidden = output.utf8.count > 0 ? true : false
        minimumFractionDigits = 0 //set default
        
        if let decimalLocation = output.range(of: currencyDecimalSeparator)?.upperBound {
            let locationValue = output.distance(from: output.endIndex, to: decimalLocation)
            minimumFractionDigits = abs(locationValue)
        }
        
        if (store.state.maxDigits == 0 && selectedRate?.code == nil) {
            currencyDecimalSeparator = ""
        }
        
        //If trailing decimal, append the decimal to the output
        hasTrailingDecimal = false //set default
        if let decimalLocation = output.range(of: currencyDecimalSeparator)?.upperBound {
            if output.endIndex == decimalLocation {
                hasTrailingDecimal = true
            }
        }

        var newAmount: Satoshis?
        if let outputAmount = NumberFormatter().number(from: output)?.doubleValue {
            if let rate = selectedRate {
                newAmount = Satoshis(value: outputAmount, rate: rate)
            } else {
                if store.state.maxDigits == 0 {
                    newAmount = Satoshis(rawValue: (NumberFormatter().number(from: output)?.uint64Value)!)
                } else if store.state.maxDigits == 2 {
                    let bits = Bits(rawValue: outputAmount)
                    newAmount = Satoshis(bits: bits)
                } else {
                    let bitcoin = Bitcoin(rawValue: outputAmount)
                    newAmount = Satoshis(bitcoin: bitcoin)
                }
            }
        }

        if let newAmount = newAmount {
            if (store.state.maxDigits == 0 && selectedRate?.code == nil && pinPad.currentOutput.last?.description == ".") {
                pinPad.removeLast()
            }
            
            if newAmount > C.maxMoney {
                pinPad.removeLast()
            } else {
                amount = newAmount
            }
        } else {
            amount = nil
        }
    }

    private func updateAmountLabel() {
        guard let amount = amount else { amountLabel.text = ""; return }
        let displayAmount = DisplayAmount(amount: amount, state: store.state, selectedRate: selectedRate, minimumFractionDigits: minimumFractionDigits)
        var output = displayAmount.description
        if hasTrailingDecimal {
            output = output.appending(NumberFormatter().currencyDecimalSeparator)
        }
        
        if (output.count > 12) {
            if (output.count > 12 && output.count <= 17) {
                amountLabel.font = .customBody(size: 24.0)
            } else if (output.count > 17 && output.count < 19) {
                amountLabel.font = .customBody(size: 22.0)
            } else if (output.count >= 19 && output.count < 20) {
                amountLabel.font = .customBody(size: 20.0)
            } else if (output.count >= 20 && output.count < 22) {
                amountLabel.font = .customBody(size: 18.0)
            } else if (output.count >= 22) {
                amountLabel.font = .customBody(size: 16.0)
            }
        } else if (amountLabel.font.pointSize != 26.0) {
            amountLabel.font = .customBody(size: 26.0)
        }
        
        amountLabel.text = output
        placeholder.isHidden = output.utf8.count > 0 ? true : false
        cursor.isHidden = !placeholder.isHidden
    }

    func updateBalanceLabel() {
        if let (balance, fee) = balanceTextForAmount?(amount, selectedRate) {
            balanceLabel.attributedText = balance
            feeLabel.attributedText = fee
            feeSelector.feeString = fee
        }
    }
    
    func updateCustomFee(fee: UInt64) -> Void {
        let feeAttributes: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.font: UIFont.customBody(size: 16.0),
            NSAttributedStringKey.foregroundColor: UIColor.grayTextTint
        ]
        let feeString = String(format: S.FeeSelector.satByte, "\(fee / C.byteShift)")
        feeSelector.feeString = NSAttributedString(string: feeString, attributes: feeAttributes)
    }

    private func toggleFeeSelector() {
        guard let height = feeSelectorHeight else { return }
        let isCollapsed: Bool = height.isActive
        UIView.spring(C.animationDuration, animations: {
            if isCollapsed {
                NSLayoutConstraint.deactivate([height])
                self.feeSelector.addIntrinsicSize()
            } else {
                self.feeSelector.removeIntrinsicSize()
                NSLayoutConstraint.activate([height])
            }
            self.parent?.parent?.view?.layoutIfNeeded()
        }, completion: {_ in })
    }

    @objc private func didTap() {
        UIView.spring(C.animationDuration, animations: {
            self.togglePinPad()
            self.parent?.parent?.view.layoutIfNeeded()
        }, completion: { completed in })
    }

    func closePinPad() {
        pinPadHeight?.constant = 0.0
        cursor.isHidden = true
        bottomBorder.isHidden = true
        // updateBalanceAndFeeLabels()
        updateBalanceLabel()
    }

    private func togglePinPad() {
        let isCollapsed: Bool = pinPadHeight?.constant == 0.0
        pinPadHeight?.constant = isCollapsed ? pinPad.height : 0.0
        cursor.isHidden = isCollapsed ? false : true
        bottomBorder.isHidden = isCollapsed ? false : true
        // updateBalanceAndFeeLabels()
        didChangeFirstResponder?(isCollapsed)
    }

    private func updateBalanceAndFeeLabels() {
        if let amount = amount, amount.rawValue > 0 {
            balanceLabel.isHidden = false
        } else {
            balanceLabel.isHidden = cursor.isHidden
        }
    }

    private func fullRefresh() {
        updateCurrencyToggleTitle()
        
        if (selectedRate == nil) {
            pinPad.setRateCode(rateCode: "")
            
            if (store.state.maxDigits == 0) {
                minimumFractionDigits = 0
            }
        } else {
            pinPad.setRateCode(rateCode: selectedRate!.code)
        }
        
        updateBalanceLabel()
        updateAmountLabel()

        //Update pinpad content to match currency change
        //This must be done AFTER the amount label has updated
        let currentOutput = amountLabel.text ?? ""
        var set = CharacterSet.decimalDigits
        set.formUnion(CharacterSet(charactersIn: NumberFormatter().currencyDecimalSeparator))
        
        pinPad.currentOutput = String(String.UnicodeScalarView(currentOutput.unicodeScalars.filter { set.contains($0) }))
    }

    private func updateCurrencyToggleTitle() {
        if let rate = selectedRate {
            self.currency.text = "\(rate.code) (\(rate.currencySymbol))"
        } else {
            self.currency.text = S.Symbols.currencyButtonTitle(maxDigits: store.state.maxDigits)
        }
        let placeholderAmount = DisplayAmount(amount: Satoshis(0), state: store.state, selectedRate: selectedRate, minimumFractionDigits: minimumFractionDigits)
        placeholder.text = placeholderAmount.description
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Fees : Equatable {}

func ==(lhs: Fees, rhs: Fees) -> Bool {
    return lhs.fastest.sats == rhs.fastest.sats && lhs.regular.sats == rhs.regular.sats && lhs.economy.sats == rhs.economy.sats
}
