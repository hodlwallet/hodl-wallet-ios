//
//  FeeUpdater.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-03-02.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import Foundation

struct FeeData {
    let sats: UInt64
    let time: NSString
    let blocks: Int
}

struct Fees {
    let fastest: FeeData
    let regular: FeeData
    let economy: FeeData
    var current: UInt64?
    
    init (fastest: FeeData, regular: FeeData, economy: FeeData, current: UInt64? = nil) {
        self.fastest = fastest
        self.regular = regular
        self.economy = economy
        self.current = current
    }
}

extension Fees {
    static var defaultFees: Fees {
        return Fees(fastest: FeeData(sats: maxFeePerKB, time: "3 to 24 hours", blocks: 2),
                    regular: FeeData(sats: defaultFeePerKB, time: "1 to 2 hours", blocks: 10),
                    economy: FeeData(sats: minFeePerKB, time: "10 to 45 minutes", blocks: 25),
                    current: defaultFeePerKB)
    }
}

private let defaultFeePerKB: UInt64 = (5000*1000 + 99)/100 // bitcoind 0.11 min relay fee on 100bytes
private let minFeePerKB: UInt64 = (191*1000 + 190)/191 // minimum relay fee on a 191byte tx
private let maxFeePerKB: UInt64 = (1000100*1000 + 190)/191 // slightly higher than a 10000bit fee on a 191byte tx

class FeeUpdater : Trackable {

    //MARK: - Public
    init(walletManager: WalletManager, store: Store) {
        self.walletManager = walletManager
        self.store = store
    }

    func refresh(completion: @escaping () -> Void) {
        walletManager.apiClient?.feePerKb { newFees, error in
            guard error == nil else { print("feePerKb error: \(String(describing: error))"); completion(); return }
            guard newFees.fastest.sats <= self.maxFeePerKB && newFees.economy.sats >= self.minFeePerKB && newFees.economy.sats < newFees.fastest.sats else {
                self.saveEvent("wallet.didUseDefaultFeePerKB")
                return
            }
            self.store.perform(action: UpdateFees.set(newFees))
            completion()
        }

        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: feeUpdateInterval, target: self, selector: #selector(intervalRefresh), userInfo: nil, repeats: true)
        }
    }

    func refresh() {
        refresh(completion: {})
    }

    @objc func intervalRefresh() {
        refresh(completion: {})
    }

    //MARK: - Private
    private let walletManager: WalletManager
    private let store: Store
    private let feeKey = "FEE_PER_KB"
    private let txFeePerKb: UInt64 = 191
    private lazy var minFeePerKB: UInt64 = {
        return ((self.txFeePerKb*1000 + 190)/191) // minimum relay fee on a 191byte tx
    }()
    private let maxFeePerKB: UInt64 = ((1000100*1000 + 190)/191) // slightly higher than a 10000bit fee on a 191byte tx
    private var timer: Timer?
    private let feeUpdateInterval: TimeInterval = 15

}
