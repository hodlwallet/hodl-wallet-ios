//
//  AddressCell.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-12-16.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

class AddressCell : UIView {

    init() {
        super.init(frame: .zero)
        setupViews()
    }

    var address: String? {
        return contentLabel.text
    }

    var didBeginEditing: (() -> Void)?
    var didReceivePaymentRequest: ((PaymentRequest) -> Void)?

    func setContent(_ content: String?) {
        contentLabel.text = content
        textField.text = content
    }

    var isEditable = false {
        didSet {
            gr.isEnabled = isEditable
        }
    }

    let textField = UITextField()
    let paste = ShadowButton(title: "", type: .tertiary, image: #imageLiteral(resourceName: "Paste"), imageColor: .whiteTint, backColor: .grayBackground)
    let scan = ShadowButton(title: "", type: .tertiary, image: #imageLiteral(resourceName: "Scan"), imageColor: .whiteTint, backColor: .grayBackground)
    fileprivate let contentLabel = UILabel(font: .customBody(size: 14.0), color: .whiteTint)
    private let pasteLabel = UILabel(font: .customBody(size: 14.0), color: .whiteTint)
    private let scanLabel = UILabel(font: .customBody(size: 14.0), color: .whiteTint)
    private let label = UILabel(font: .customBody(size: 16.0))
    fileprivate let gr = UITapGestureRecognizer()
    fileprivate let tapView = UIView()
    private let border = UIView(color: .secondaryGrayText)

    private func setupViews() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    private func addSubviews() {
        addSubview(label)
        addSubview(pasteLabel)
        addSubview(scanLabel)
        addSubview(contentLabel)
        addSubview(textField)
        addSubview(tapView)
        addSubview(border)
        addSubview(paste)
        addSubview(scan)
    }

    private func addConstraints() {
        label.constrain([
            label.constraint(.centerY, toView: self),
            label.constraint(.leading, toView: self, constant: C.padding[2]) ])
        contentLabel.constrain([
            contentLabel.constraint(.leading, toView: label),
            contentLabel.constraint(toBottom: label, constant: 0.0),
            contentLabel.trailingAnchor.constraint(equalTo: paste.leadingAnchor, constant: -C.padding[1]) ])
        textField.constrain([
            textField.constraint(.leading, toView: label),
            textField.constraint(toBottom: label, constant: 0.0),
            textField.trailingAnchor.constraint(equalTo: paste.leadingAnchor, constant: -C.padding[1]) ])
        tapView.constrain([
            tapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapView.topAnchor.constraint(equalTo: topAnchor),
            tapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tapView.trailingAnchor.constraint(equalTo: paste.leadingAnchor) ])
        scanLabel.constrain([
            scanLabel.centerXAnchor.constraint(equalTo: scan.centerXAnchor, constant: -3.0),
            scanLabel.bottomAnchor.constraint(equalTo: scan.topAnchor, constant: -C.padding[2]) ])
        pasteLabel.constrain([
            pasteLabel.centerXAnchor.constraint(equalTo: paste.centerXAnchor, constant: -3.0),
            pasteLabel.bottomAnchor.constraint(equalTo: paste.topAnchor, constant: -C.padding[2]) ])
        scan.constrain([
            scan.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -C.padding[2]),
            scan.centerYAnchor.constraint(equalTo: centerYAnchor),
            scan.widthAnchor.constraint(equalToConstant: 15.0)])
        paste.constrain([
            paste.centerYAnchor.constraint(equalTo: centerYAnchor),
            paste.trailingAnchor.constraint(equalTo: scan.leadingAnchor, constant: -C.padding[3]),
            paste.widthAnchor.constraint(equalToConstant: 15.0) ])
        border.constrain([
            border.leadingAnchor.constraint(equalTo: leadingAnchor),
            border.bottomAnchor.constraint(equalTo: bottomAnchor),
            border.trailingAnchor.constraint(equalTo: trailingAnchor),
            border.heightAnchor.constraint(equalToConstant: 1.0) ])
    }

    private func setInitialData() {
        label.text = S.Send.toLabel
        pasteLabel.text = S.Send.pasteLabel
        scanLabel.text = S.Send.scanLabel
        textField.font = contentLabel.font
        textField.textColor = contentLabel.textColor
        textField.isHidden = true
        textField.returnKeyType = .done
        textField.delegate = self
        textField.clearButtonMode = .whileEditing
        textField.tintColor = .grayTextTint
        textField.keyboardAppearance = .dark
        label.textColor = .whiteTint
        contentLabel.lineBreakMode = .byTruncatingMiddle

        textField.editingChanged = strongify(self) { myself in
            myself.contentLabel.text = myself.textField.text
        }

        //GR to start editing label
        gr.addTarget(self, action: #selector(didTap))
        tapView.addGestureRecognizer(gr)
    }

    @objc private func didTap() {
        textField.becomeFirstResponder()
        contentLabel.isHidden = true
        textField.isHidden = false
        if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
            clearButton.setImage(#imageLiteral(resourceName: "smallclose"), for: .normal)
            // Must fix clear button color
            clearButton.imageView?.tintColor = .gradientStart
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AddressCell : UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        didBeginEditing?()
        contentLabel.isHidden = true
        gr.isEnabled = false
        tapView.isUserInteractionEnabled = false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        contentLabel.isHidden = false
        textField.isHidden = true
        gr.isEnabled = true
        tapView.isUserInteractionEnabled = true
        contentLabel.text = textField.text
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let request = PaymentRequest(string: string) {
            didReceivePaymentRequest?(request)
            return false
        } else {
            return true
        }
    }
}
