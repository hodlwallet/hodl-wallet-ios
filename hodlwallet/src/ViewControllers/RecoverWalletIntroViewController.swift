//
//  RecoverWalletIntroViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-02-23.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

class RecoverWalletIntroViewController : UIViewController {

    //MARK: - Public
    init(didTapNext: @escaping () -> Void) {
        self.didTapNext = didTapNext
        super.init(nibName: nil, bundle: nil)
    }

    //MARK: - Private
    private let didTapNext: () -> Void
    private let header = RadialGradientView(backgroundColor: .grayBackground)
    private let nextButton = ShadowButton(title: S.RecoverWallet.next, type: .primary)
    private let label = UILabel(font: .customBody(size: 16.0), color: .gradientStart)
    private let illustration = UIImageView(image: #imageLiteral(resourceName: "RecoverWalletIllustration"))

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setData()
    }

    private func addSubviews() {
        view.addSubview(header)
        header.addSubview(illustration)
        view.addSubview(nextButton)
        view.addSubview(label)
    }

    private func addConstraints() {
        header.constrainTopCorners(sidePadding: 0.0, topPadding: 0.0)
        header.constrain([header.heightAnchor.constraint(equalToConstant: C.Sizes.largeHeaderHeight)])
        illustration.constrain([
            illustration.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            illustration.centerYAnchor.constraint(equalTo: header.centerYAnchor, constant: C.padding[2]) ])
        label.constrain([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: header.bottomAnchor, constant: C.padding[2]) ])
        nextButton.constrain([
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nextButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: C.Sizes.buttonHeight) ])
    }

    private func setData() {
        view.backgroundColor = .grayBackground
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.text = S.RecoverWallet.intro
        nextButton.tap = didTapNext
        title = S.RecoverWallet.header
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
