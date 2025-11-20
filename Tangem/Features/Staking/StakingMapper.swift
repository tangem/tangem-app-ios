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

struct StakingTransactionMapper {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem

    init(tokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
    }

    func mapToStakeKitTransactions(action: StakingTransactionAction) -> [StakingTransaction] {
        action.transactions.map { transaction in
            let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: action.amount)
            let feeAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: transaction.fee)

            let params = StakeKitTransactionParams(
                type: .init(rawValue: transaction.type),
                status: .init(rawValue: transaction.status),
                stepIndex: transaction.stepIndex,
                validator: action.validator,
                solanaBlockhashDate: Date()
            )
            let stakeKitTransaction = StakingTransaction(
                id: transaction.id,
                amount: amount,
                fee: Fee(feeAmount),
                unsignedData: transaction.unsignedTransactionData,
                params: params
            )

            return stakeKitTransaction
        }
    }
}
