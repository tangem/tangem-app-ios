//
//  ValidatingStakingTransactionDecorator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct ValidatingStakingTransactionDecorator: TransactionDispatcher {
    private let decoratee: TransactionDispatcher
    private let validator: StakingTransactionValidator?

    init(decoratee: TransactionDispatcher, validator: StakingTransactionValidator?) {
        self.decoratee = decoratee
        self.validator = validator
    }

    var hasNFCInteraction: Bool {
        decoratee.hasNFCInteraction
    }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        if case .staking(let action) = transaction {
            let rawTransactions = action.transactions.compactMap { tx -> String? in
                guard case .raw(let data) = tx.unsignedTransactionData else { return nil }
                return data
            }

            if let validator {
                guard !rawTransactions.isEmpty else {
                    throw StakingTransactionValidationError.emptyOrMalformedData
                }

                try await validator.validate(rawTransactions)
            }
        }

        return try await decoratee.send(transaction: transaction)
    }
}
