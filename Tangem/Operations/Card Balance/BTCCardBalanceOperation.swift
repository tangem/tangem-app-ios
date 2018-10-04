//
//  BTCCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class BTCCardBalanceOperation: CardBalanceOperation {
    
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }
        
        card.mult = priceUSD
        
        let address = card.isTestNet ? card.btcAddressTest : card.btcAddressMain
        let operation = BitcoinNetworkBalanceOperation(address: address, isTestNet: card.isTestNet) { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleBalanceLoaded(balanceValue: value)
            case .failure(let error):
                self?.card.mult = 0
                self?.failOperationWith(error: error)
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func handleBalanceLoaded(balanceValue: Double) {
        guard !isCancelled else {
            return
        }
        
        card.value = Int(balanceValue)
        
        let walletValue = balanceValue / 100000000.0
        card.walletValue = self.balanceFormatter.string(from: NSNumber(value: walletValue))!
        
        let usdWalletValue = walletValue * card.mult
        card.usdWalletValue = self.balanceFormatter.string(from: NSNumber(value: usdWalletValue))!

        completeOperation()
    }
    
}
