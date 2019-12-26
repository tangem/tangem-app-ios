//
//  BCHCardBalanceOperation.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation

class BCHCardBalanceOperation: BaseCardBalanceOperation {
    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }

        card.mult = priceUSD
        handleBalanceLoaded(balanceValue: "---")
//        let operation = BtcBalanceOperation(with: card.cardEngine as! BTCEngine, completion: { [weak self] result in
//            switch result {
//            case .success(let response):
//
//                let engine = self?.card.cardEngine as! BTCEngine
//                engine.addressResponse = response
//                self?.handleBalanceLoaded(balanceValue: "\(response.balance.rounded(blockchain: .bitcoin))")
//            case .failure(let error):
//                self?.card.mult = 0
//                self?.failOperationWith(error: error)
//            }
//        })
//
//        operationQueue.addOperation(operation)
    }

    func handleBalanceLoaded(balanceValue: String) {
        guard !isCancelled else {
            return
        }
        
        card.walletValue = balanceValue

        completeOperation()
    }
}
