//
//  BTCCardBalanceOperation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

class CardanoCardBalanceOperation: BaseCardBalanceOperation {

    override func handleMarketInfoLoaded(priceUSD: Double) {
        guard !isCancelled else {
            return
        }

        card.mult = priceUSD

        let operation = CardanoNetworkBalanceOperation(address: card.address) { [weak self] (result) in
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

        let walletValue = balanceValue / 1000000.0
        card.walletValue = String(walletValue)

        let usdWalletValue = walletValue * card.mult
        card.usdWalletValue = String(usdWalletValue)

        completeOperation()
    }

}
