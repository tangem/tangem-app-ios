//
//  BNBCardBalanceOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class BNBCardBalanceOperation: BaseCardBalanceOperation {
    
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }
        
        card.mult = priceUSD
        
        let operation = BinanceNetworkBalanceOperation(address: card.address, isTestNet: card.isTestBlockchain) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleBalanceLoaded(balanceValue: value.0, account: value.1, sequence: value.2)
            case .failure(let error):
                self?.card.mult = 0
                self?.failOperationWith(error: error)
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func handleBalanceLoaded(balanceValue: String, account: Int, sequence: Int) {
        guard !isCancelled else {
            return
        }
        
        card.walletValue = balanceValue
        let engine = (card.cardEngine as! BinanceEngine)
        engine.txBuilder.binanceWallet.sequence = sequence
        engine.txBuilder.binanceWallet.accountNumber = account
        completeOperation()
    }
    
}
