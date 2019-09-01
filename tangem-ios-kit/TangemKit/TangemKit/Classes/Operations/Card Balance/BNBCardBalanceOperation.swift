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
                self?.handleBalanceLoaded(balanceValue: value)
            case .failure(let error):
                self?.card.mult = 0
                self?.failOperationWith(error: error)
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func handleBalanceLoaded(balanceValue: String) {
        guard !isCancelled else {
            return
        }
        
        card.walletValue = balanceValue
        
        completeOperation()
    }
    
}
