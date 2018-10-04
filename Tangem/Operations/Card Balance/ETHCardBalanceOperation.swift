//
//  ETHCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class ETHCardBalanceOperation: CardBalanceOperation {
    
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }
        
        card.mult = priceUSD
        
        let operation = EthereumNetworkBalanceOperation(address: card.ethAddress, isTestNet: card.isTestNet) { [weak self] (result) in
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
    
    func handleBalanceLoaded(balanceValue: UInt64) {
        guard !isCancelled else {
            return
        }
        
        card.valueUInt64 = balanceValue
        
        let wei = Double(card.valueUInt64)
        let walletValue = wei / 1000000000000000000.0
        card.walletValue = self.balanceFormatter.string(from: NSNumber(value: walletValue))!
        
        let usdWalletValue = walletValue * card.mult
        card.usdWalletValue = self.balanceFormatter.string(from: NSNumber(value: usdWalletValue))!
        
        completeOperation()
    }
    
}
