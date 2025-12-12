//
//  StakingTransactionMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking
import TangemFoundation

struct StakingTransactionMapper {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }

    func mapToStakeKitTransactions(
        action: StakingTransactionAction
    ) throws -> [StakeKitTransaction] {
        try action.transactions.map { transaction -> StakeKitTransaction in
            guard case .raw(let unsignedTransactionData) = transaction.unsignedTransactionData,
                  let metadata = transaction.metadata as? StakeKitTransactionMetadata else {
                throw StakingTransactionMapper.Error.invalidTransactionData
            }

            let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: action.amount)
            let feeAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: transaction.fee)

            return StakeKitTransaction(
                id: metadata.id,
                amount: amount,
                fee: Fee(feeAmount),
                unsignedData: unsignedTransactionData,
                type: .init(rawValue: metadata.type),
                status: .init(rawValue: metadata.status),
                stepIndex: metadata.stepIndex,
                target: action.target,
                solanaBlockhashDate: Date()
            )
        }
    }

    func mapToP2PTransactions(
        action: StakingTransactionAction
    ) throws -> [P2PTransaction] {
        try action.transactions.map { transaction -> P2PTransaction in
            guard case .compiledEthereum(let unsignedTransactionData) = transaction.unsignedTransactionData else {
                throw StakingTransactionMapper.Error.invalidTransactionData
            }

            let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: action.amount)
            let feeAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: transaction.fee)

            return P2PTransaction(
                amount: amount,
                fee: Fee(feeAmount),
                unsignedData: unsignedTransactionData,
                target: action.target
            )
        }
    }
}

extension StakingTransactionMapper {
    enum Error: Swift.Error {
        case invalidTransactionData
    }
}
