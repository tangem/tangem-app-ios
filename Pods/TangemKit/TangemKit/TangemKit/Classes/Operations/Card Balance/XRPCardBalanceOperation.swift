//
//  ETHCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class XRPCardBalanceOperation: BaseCardBalanceOperation {

    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }

        card.mult = priceUSD

        let operation = RippleNetworkBalanceOperation(address: card.address) { [weak self] (result) in
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
        
        let operation = RippleNetworkReserveOperation { [weak self] (result) in
            switch result {
            case .success(let value):
                self?.handleReserveLoaded(reserve: value)
            case .failure(let error):
                self?.failOperationWith(error: error)
            }
        }
        operationQueue.addOperation(operation)
    }
    
    func handleReserveLoaded(reserve: String) {
        guard !isCancelled else {
            return
        }
        
        if let xrpEngine = card.cardEngine as? RippleEngine {
            xrpEngine.walletReserve = reserve
        }
        
        guard let balanceValue = Double(card.walletValue), let reserveValue = Double(reserve) else {
            assertionFailure()
            completeOperation()
            return
        }

        card.walletValue = NSDecimalNumber(value: balanceValue).subtracting(NSDecimalNumber(value: reserveValue)).stringValue
        
        completeOperation()
    }

}
