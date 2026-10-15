//
//  CollectiblesDepositTransactionCreator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct CollectiblesDepositTransactionCreator: SendTransactionCreator {
    func createTransaction(
        amount: Amount,
        fee: Fee,
        destinationAddress: String,
        params: TransactionParams?
    ) async throws -> BSDKTransaction {
        throw CollectiblesDepositSendingUnsupportedError.sendingUnsupported
    }
}
