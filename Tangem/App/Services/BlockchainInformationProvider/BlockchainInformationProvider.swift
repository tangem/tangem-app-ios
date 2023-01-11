//
//  BlockchainInformationProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import TangemExchange
import BlockchainSdk

protocol BlockchainInformationProviding {
    func hasPendingTransaction(currency: Currency) -> Bool
}

struct  BlockchainInformationProvider {
    let wallet: Wallet
}

extension BlockchainInformationProvider: BlockchainInformationProviding {
    func hasPendingTransaction(currency: Currency) -> Bool {
        guard wallet.blockchain.networkId == currency.blockchain.networkId else {
            assertionFailure("Incorrect Wallet")
            return false
        }

        return wallet.hasPendingTx
    }
}
