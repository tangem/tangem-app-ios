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
    ) -> [StakeKitTransaction] {
        action.transactions.compactMap { transaction -> StakeKitTransaction? in
            guard case .raw(let unsignedTransactionData) = transaction.unsignedTransactionData else {
                return nil
            }

            let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: action.amount)
            let feeAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: transaction.fee)

            return StakeKitTransaction(
                id: transaction.id,
                amount: amount,
                fee: Fee(feeAmount),
                unsignedData: unsignedTransactionData,
                type: .init(rawValue: transaction.type),
                status: .init(rawValue: transaction.status),
                stepIndex: transaction.stepIndex,
                validator: action.validator,
                solanaBlockhashDate: Date()
            )
        }
    }

    func mapToP2PTransactions(
        action: StakingTransactionAction
    ) -> [P2PTransaction] {
        action.transactions.compactMap { transaction -> P2PTransaction? in
            guard case .compiledEthereum(let unsignedTransactionData) = transaction.unsignedTransactionData else {
                return nil
            }

            let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: action.amount)
            let feeAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: transaction.fee)

            return P2PTransaction(
                amount: amount,
                fee: Fee(feeAmount),
                unsignedData: unsignedTransactionData,
            )
        }
    }
}
