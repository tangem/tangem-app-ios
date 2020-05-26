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
        
        let operation = BinanceNetworkBalanceOperation(address: card.address, token: card.tokenContractAddress, isTestNet: card.isTestBlockchain) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleBalanceLoaded(balanceValue: value.0, tokenValue: value.1, account: value.2, sequence: value.3)
            case .failure(let error):
                self?.card.mult = 0
                if error.localizedDescription.contains(find: "account not found") {
                    self?.card.hasAccount = false
                    self?.failOperationWith(error: "Account not found")
                } else {
                    self?.failOperationWith(error: error)
                }
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func handleBalanceLoaded(balanceValue: String, tokenValue: String?, account: Int, sequence: Int) {
        guard !isCancelled else {
            return
        }
        
        card.walletValue = balanceValue
        card.walletTokenValue = tokenValue
        let engine = (card.cardEngine as! BinanceEngine)
        engine.txBuilder.binanceWallet.sequence = sequence
        engine.txBuilder.binanceWallet.accountNumber = account
        completeOperation()
    }
    
}
