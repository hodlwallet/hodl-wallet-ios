//
//  StartImportViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-06-13.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit
import BRCore

private let utxoApiURL = "https://blockstream.info/api/address/%@/utxo"
private let utxoApiFalbackURL = "https://blockstream.info/api/address/%@/utxo"
private let utxoApiTestnetURL = "https://blockstream.info/testnet/api/address/%@/utxo"

private let txApiURL = "https://blockstream.info/api/tx/%@"
private let txApiFalbackURL = "https://blockstream.info/api/tx/%@"
private let txApiTestnetURL = "https://blockstream.info/testnet/api/tx/%@"

class StartImportViewController : UIViewController {

    init(walletManager: WalletManager, store: Store) {
        self.walletManager = walletManager
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    private let walletManager: WalletManager
    private let store: Store
    private let header = RadialGradientView(backgroundColor: .grayBackground, offset: 64.0)
    private let illustration = UIImageView(image: #imageLiteral(resourceName: "ImportIllustration"))
    private let message = UILabel.wrapping(font: .customBody(size: 16.0), color: .gradientStart)
    private let warning = UILabel.wrapping(font: .customBody(size: 16.0), color: .whiteTint)
    private let button = ShadowButton(title: S.Import.scan, type: .primary)
    private let bullet = UIImageView(image: #imageLiteral(resourceName: "deletecircle"))
    private let leftCaption = UILabel.wrapping(font: .customMedium(size: 13.0), color: .whiteTint)
    private let rightCaption = UILabel.wrapping(font: .customMedium(size: 13.0), color: .whiteTint)
    private let balanceActivity = BRActivityViewController(message: S.Import.checking)
    private let importingActivity = BRActivityViewController(message: S.Import.importing)
    private let unlockingActivity = BRActivityViewController(message: S.Import.unlockingActivity)

    override func viewDidLoad() {
        addSubviews()
        addConstraints()
        setInitialData()
    }

    private func addSubviews() {
        view.addSubview(header)
        header.addSubview(illustration)
        header.addSubview(leftCaption)
        header.addSubview(rightCaption)
        view.addSubview(message)
        view.addSubview(button)
        view.addSubview(bullet)
        view.addSubview(warning)
    }

    private func addConstraints() {
        header.constrainTopCorners(sidePadding: 0, topPadding: 0)
        header.constrain([
            header.constraint(.height, constant: 220.0) ])
        illustration.constrain([
            illustration.constraint(.width, constant: 64.0),
            illustration.constraint(.height, constant: 84.0),
            illustration.constraint(.centerX, toView: header, constant: 0.0),
            illustration.constraint(.centerY, toView: header, constant: C.padding[7]) ])
        leftCaption.constrain([
            leftCaption.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: C.padding[1]),
            leftCaption.trailingAnchor.constraint(equalTo: header.centerXAnchor, constant: -C.padding[2]),
            leftCaption.widthAnchor.constraint(equalToConstant: 80.0)])
        rightCaption.constrain([
            rightCaption.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: C.padding[1]),
            rightCaption.leadingAnchor.constraint(equalTo: header.centerXAnchor, constant: C.padding[2]),
            rightCaption.widthAnchor.constraint(equalToConstant: 80.0)])
        message.constrain([
            message.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            message.topAnchor.constraint(equalTo: header.bottomAnchor, constant: C.padding[7]),
            message.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]) ])
        bullet.constrain([
            bullet.leadingAnchor.constraint(equalTo: message.leadingAnchor),
            bullet.topAnchor.constraint(equalTo: message.bottomAnchor, constant: C.padding[4]),
            bullet.widthAnchor.constraint(equalToConstant: 16.0),
            bullet.heightAnchor.constraint(equalToConstant: 16.0) ])
        warning.constrain([
            warning.leadingAnchor.constraint(equalTo: bullet.trailingAnchor, constant: C.padding[2]),
            warning.topAnchor.constraint(equalTo: bullet.topAnchor, constant: 0.0),
            warning.trailingAnchor.constraint(equalTo: message.trailingAnchor) ])
        button.constrain([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.constraint(.height, constant: C.Sizes.buttonHeight) ])
    }

    private func setInitialData() {
        view.backgroundColor = .grayBackground
        illustration.contentMode = .scaleAspectFill
        message.text = S.Import.importMessage
        leftCaption.text = S.Import.leftCaption
        leftCaption.textAlignment = .center
        rightCaption.text = S.Import.rightCaption
        rightCaption.textAlignment = .center
        leftCaption.isHidden = true
        rightCaption.isHidden = true
        warning.text = S.Import.importWarning

        button.tap = { [weak self] in
            let scan = ScanViewController(scanKeyCompletion: { address in
                self?.didReceiveAddress(address)
            }, isValidURI: { (string) -> Bool in
                return string.isValidPrivateKey || string.isValidBip38Key
            })
            self?.parent?.present(scan, animated: true, completion: nil)
        }
    }

    private func didReceiveAddress(_ address: String) {
        if address.isValidPrivateKey {
            if let key = BRKey(privKey: address) {
                checkBalance(key: key)
            }
        } else if address.isValidBip38Key {
            unlock(address: address, callback: { key in
                self.checkBalance(key: key)
            })
        }
    }

    private func unlock(address: String, callback: @escaping (BRKey) -> Void) {
        let alert = UIAlertController(title: S.Import.title, message: S.Import.password, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = S.Import.passwordPlaceholder
            textField.isSecureTextEntry = true
            textField.returnKeyType = .done
            textField.keyboardAppearance = .dark
        })
        alert.addAction(UIAlertAction(title: S.Button.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: { _ in
            self.present(self.unlockingActivity, animated: true, completion: {
                if let password = alert.textFields?.first?.text {
                    if let key = BRKey(bip38Key: address, passphrase: password) {
                        self.unlockingActivity.dismiss(animated: true, completion: {
                            callback(key)
                        })
                        return
                    }
                }
                self.unlockingActivity.dismiss(animated: true, completion: {
                    self.showErrorMessage(S.Import.wrongPassword)
                })
            })
        }))
        present(alert, animated: true, completion: nil)
    }

    private func checkBalance(key: BRKey) {
        var utxos = [SimpleUTXO]()
        var key = key
        
        guard let bech32Address = key.address() else { return }
        guard let legacyAddress = key.legacyAddress() else { return }
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        present(balanceActivity, animated: true, completion: {
            for (_, address) in [bech32Address, legacyAddress].enumerated() {
                dispatchGroup.enter()
                
                let utxoUrlString = String(format: (E.isTestnet ? utxoApiTestnetURL : utxoApiURL), address)
                let utxoRequest = NSMutableURLRequest(url: URL(string: utxoUrlString)!,
                                                  cachePolicy: .reloadIgnoringLocalCacheData,
                                                  timeoutInterval: 20.0)
                utxoRequest.httpMethod = "GET"
                let utxoTask = (URLSession.shared.dataTask(with: utxoRequest as URLRequest) { data, response, error in
                    guard error == nil else { print("error: \(error!)"); return }
                    
                    guard let data       = data,
                        let jsonData     = try? JSONSerialization.jsonObject(with: data, options: []),
                        let jsonRootArray = jsonData as? NSArray else {
                            self.handleData(outputs: utxos, key: key)
                            
                            return
                        }
                    
                    for (_, txData) in jsonRootArray.enumerated() {
                        guard let tx   = txData as? NSDictionary,
                            let txid   = tx.value(forKey: "txid") as? String,
                            let vout   = tx.value(forKey: "vout") as? Int,
                            let status = tx.value(forKey: "status") as? NSDictionary,
                            let value  = tx.value(forKey: "value") as? UInt64 else {
                                self.handleData(outputs: utxos, key: key)
                                
                                return
                            }
                        
                        // Check the status is confirmed only add confirmed transactions
                        if (status.value(forKey: "confirmed") as! Bool) {
                            dispatchGroup.enter()
                            
                            // If the transaction is confirmed we look for the utxo script pub key from the tx api
                            let txUrlString = String(format: (E.isTestnet ? txApiTestnetURL : txApiURL), txid)
                            let txRequest = NSMutableURLRequest(url: URL(string: txUrlString)!,
                                                                  cachePolicy: .reloadIgnoringLocalCacheData,
                                                                  timeoutInterval: 20.0)
                            txRequest.httpMethod = "GET"
                            let txTask = (URLSession.shared.dataTask(with: txRequest as URLRequest) { data, response, error in
                                guard error == nil else { print("error: \(error!)"); return }
                                
                                guard let data       = data,
                                    let jsonData     = try? JSONSerialization.jsonObject(with: data, options: []),
                                    let jsonRootDict = jsonData as? NSDictionary,
                                    let vouts        = jsonRootDict.value(forKey: "vout") as? NSArray else {
                                        self.handleData(outputs: utxos, key: key)
                                        
                                        return
                                    }
                                
                                // Check if the index is valid in the vouts array
                                if (vouts.count >= (vout + 1)) {
                                    guard let voutItem   = vouts[vout] as? NSDictionary,
                                        let scriptPubKey = voutItem.value(forKey: "scriptpubkey") as? String else {
                                        self.handleData(outputs: utxos, key: key)
                                        
                                        return
                                    }
                                    
                                    guard let hashData = txid.hexToData,
                                        let scriptData = scriptPubKey.hexToData else {
                                            self.handleData(outputs: utxos, key: key)
                                            
                                            return
                                    }
                                    
                                    // Lets finally add the utxo
                                    utxos.append(SimpleUTXO(
                                        hash: hashData.reverse.uInt256,
                                        index: UInt32(vout),
                                        script: [UInt8](scriptData),
                                        satoshis: value)!
                                    )
                                }
                                
                                dispatchGroup.leave()
                            })
                            
                            txTask.resume()
                        }
                    }
                    
                    dispatchGroup.leave()
                })
                
                utxoTask.resume()
            }
            
            dispatchGroup.leave()
        })
        
        dispatchGroup.notify(queue: DispatchQueue.global()) {
            self.handleData(outputs: utxos, key: key)
        }
    }

    private func handleData(outputs: [SimpleUTXO], key: BRKey) {
        var key = key
        guard let tx = UnsafeMutablePointer<BRTransaction>() else { return }
        guard let wallet = walletManager.wallet else { return }
        guard let address = key.legacyAddress() else { return }
        guard !wallet.containsAddress(address) else {
            return showErrorMessage(S.Import.Error.duplicate)
        }
        let balance = outputs.map { $0.satoshis }.reduce(0, +)
        outputs.forEach { output in
            tx.addInput(txHash: output.hash, index: output.index, amount: output.satoshis, script: output.script)
        }

        let pubKeyLength = key.pubKey()?.count ?? 0
        let fee = wallet.feeForTxSize(tx.size + 34 + (pubKeyLength - 34)*tx.inputs.count)
        balanceActivity.dismiss(animated: true, completion: {
            guard outputs.count > 0 && balance > 0 else {
                return self.showErrorMessage(S.Import.Error.empty)
            }
            guard fee + wallet.minOutputAmount <= balance else {
                return self.showErrorMessage(S.Import.Error.highFees)
            }
            guard let rate = self.store.state.currentRate else { return }
            let balanceAmount = Amount(amount: balance, rate: rate, maxDigits: self.store.state.maxDigits)
            let feeAmount = Amount(amount: fee, rate: rate, maxDigits: self.store.state.maxDigits)
            let balanceText = self.store.state.isBtcSwapped ? balanceAmount.localCurrency : balanceAmount.bits
            let feeText = self.store.state.isBtcSwapped ? feeAmount.localCurrency : feeAmount.bits
            let message = String(format: S.Import.confirm, balanceText, feeText)
            let alert = UIAlertController(title: S.Import.title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: S.Button.cancel, style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: S.Import.importButton, style: .default, handler: { _ in
                self.publish(tx: tx, balance: balance, fee: fee, key: key)
            }))
            self.present(alert, animated: true, completion: nil)
        })
    }

    private func publish(tx: UnsafeMutablePointer<BRTransaction>, balance: UInt64, fee: UInt64, key: BRKey) {
        present(importingActivity, animated: true, completion: {
            guard let wallet = self.walletManager.wallet else { return }
            guard let script = BRAddress(string: wallet.receiveAddress)?.scriptPubKey else { return }
            tx.addOutput(amount: balance - fee, script: script)
            var keys = [key]
            let _ = tx.sign(keys: &keys)

                guard tx.isSigned else {
                    self.importingActivity.dismiss(animated: true, completion: {
                        self.showErrorMessage(S.Import.Error.signing)
                    })
                    return
                }
                self.walletManager.peerManager?.publishTx(tx, completion: { [weak self] success, error in
                    guard let myself = self else { return }
                    myself.importingActivity.dismiss(animated: true, completion: {
                        DispatchQueue.main.async {
                            if let error = error {
                                myself.showErrorMessage(error.localizedDescription)
                                return
                            }
                            myself.showSuccess()
                        }
                    })
                })
        })
    }

    private func showSuccess() {
        store.perform(action: Alert.Show(.sweepSuccess(callback: { [weak self] in
            guard let myself = self else { return }
            myself.dismiss(animated: true, completion: nil)
        })))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Data {
    var reverse: Data {
        let tempBytes = Array(([UInt8](self)).reversed())
        return Data(bytes: tempBytes)
    }
}
