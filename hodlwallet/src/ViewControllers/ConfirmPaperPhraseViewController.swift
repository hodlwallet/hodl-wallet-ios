//
//  ConfirmPaperPhraseViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-10-27.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

class ConfirmPaperPhraseViewController : UIViewController {

    init(store: Store, walletManager: WalletManager, pin: String, callback: @escaping () -> Void) {
        self.store = store
        self.pin = pin
        self.walletManager = walletManager
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
        if !E.isIPhone4 {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        }
    }

    private let label = UILabel.wrapping(font: UIFont.customBody(size: 16.0))

    lazy private var confirmFirstPhrase: ConfirmPhrase = { ConfirmPhrase(text: String(format:S.ConfirmPaperPhrase.word, "\(self.indices.0 + 1)"), word: self.words[self.indices.0]) }()
    lazy private var confirmSecondPhrase: ConfirmPhrase = { ConfirmPhrase(text: String(format:S.ConfirmPaperPhrase.word, "\(self.indices.1 + 1)"), word: self.words[self.indices.1]) }()
    private let submit = ShadowButton(title: S.Button.submit, type: .primary)
    private let header = RadialGradientView(backgroundColor: .grayBackground)
    private let store: Store
    private let pin: String
    private let walletManager: WalletManager
    private let callback: () -> Void
    
    //Select 2 random indices from 1 to 10. The second number must
    //be at least one number away from the first.
    private let indices: (Int, Int) = {
        func random() -> Int { return Int(arc4random_uniform(10) + 1) }
        let first = random()
        var second = random()
        while !(abs(Int32(second - first)) > 1) {
            second = random()
        }
        return (first, second)
    }()
    lazy private var words: [String] = {
        guard let phraseString = self.walletManager.seedPhrase(pin: self.pin) else { return [] }
        return phraseString.components(separatedBy: " ")
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        view.backgroundColor = .grayBackground
        label.text = S.ConfirmPaperPhrase.label
        label.textAlignment = .center
        label.textColor = .gradientStart
        
        addSubviews()
        addConstraints()
        addButtonActions()

        confirmFirstPhrase.textField.becomeFirstResponder()

        NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: nil) { [weak self] note in
            self?.dismiss(animated: true, completion: nil)
        }

        let faqButton = UIButton.buildFaqButton(store: store, articleId: ArticleIds.confirmPhrase)
        faqButton.tintColor = .grayTextTint
        navigationItem.rightBarButtonItems = [UIBarButtonItem.negativePadding, UIBarButtonItem(customView: faqButton)]
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func addSubviews() {
        view.addSubview(header)
        header.addSubview(label)
        view.addSubview(confirmFirstPhrase)
        view.addSubview(confirmSecondPhrase)
        view.addSubview(submit)
    }

    private func addConstraints() {
        header.constrainTopCorners(sidePadding: 0, topPadding: 0)
        header.constrain([
            header.constraint(.height, constant: 185.0) ])
        label.constrain([
            label.constraint(.centerY, toView: header, constant: 10.0),
            label.constraint(.leading, toView: header, constant: 20.0),
            label.constraint(.trailing, toView: header, constant: -20.0) ])
        confirmFirstPhrase.constrain([
            confirmFirstPhrase.constraint(toBottom: header, constant: 0.0),
            confirmFirstPhrase.constraint(.width, toView: view, constant: 0.0),
            confirmFirstPhrase.constraint(.centerX, toView: view, constant: 0.0) ])
        confirmSecondPhrase.constrain([
            confirmSecondPhrase.constraint(toBottom: confirmFirstPhrase, constant: 0.0),
            confirmSecondPhrase.constraint(.width, toView: view, constant: 0.0),
            confirmSecondPhrase.constraint(.centerX, toView: view, constant: 0.0) ])
    }

    private func addButtonActions() {
        submit.addTarget(self, action: #selector(checkTextFields), for: .touchUpInside)
        confirmFirstPhrase.callback = { [weak self] in
            self?.confirmSecondPhrase.textField.becomeFirstResponder()
        }
        if E.isIPhone4 {
            confirmSecondPhrase.textField.returnKeyType = .done
            confirmSecondPhrase.doneCallback = strongify(self) { myself in
                myself.checkTextFields()
            }
        }
    }

    private func addSubmitButtonConstraints(keyboardHeight: CGFloat) {
        submit.constrain([
            NSLayoutConstraint(item: submit, attribute: .bottom, relatedBy: .equal, toItem: bottomLayoutGuide, attribute: .top, multiplier: 1.0, constant: -2.5 - keyboardHeight),
            submit.constraint(.leading, toView: view, constant: C.padding[9]),
            submit.constraint(.trailing, toView: view, constant: -C.padding[9]),
            submit.constraint(.height, constant: 40.0) ])
    }

    @objc private func checkTextFields() {
        if confirmFirstPhrase.textField.text == words[indices.0] && confirmSecondPhrase.textField.text == words[indices.1] {
            UserDefaults.writePaperPhraseDate = Date()
            store.trigger(name: .didWritePaperKey)
            callback()
        } else {
            confirmFirstPhrase.validate()
            confirmSecondPhrase.validate()
            showErrorMessage(S.ConfirmPaperPhrase.error)
        }
    }

    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let frameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        self.addSubmitButtonConstraints(keyboardHeight: frameValue.cgRectValue.height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
