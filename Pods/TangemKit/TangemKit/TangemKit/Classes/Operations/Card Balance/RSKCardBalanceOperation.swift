//
//  ETHCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class RSKCardBalanceOperation: BaseCardBalanceOperation {

    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }

        card.mult = priceUSD

        let operation = RootstockNetworkBalanceOperation(address: card.address) { [weak self] (result) in
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

        let decimalCount: Int16 = 18
        let walletValue = NSDecimalNumber(value: card.valueUInt64).dividing(by: NSDecimalNumber(value: 1).multiplying(byPowerOf10: decimalCount))
        card.walletValue = walletValue.stringValue

        completeOperation()
    }

}
