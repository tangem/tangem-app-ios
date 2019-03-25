//
//  BTCCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class BTCCardBalanceOperation: BaseCardBalanceOperation {

    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }

        card.mult = priceUSD

        let operation = BitcoinNetworkBalanceOperation(address: card.address) { [weak self] (result) in
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
        card.valueUInt64 = UInt64(balanceValue)

        let decimalCount: Int16 = 8
        let walletValue = NSDecimalNumber(value: card.valueUInt64).dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: decimalCount))
        card.walletValue = walletValue.stringValue

        completeOperation()
    }

}
