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

    func mapToStakeKitTransactions(action: StakingTransactionAction) -> [StakeKitTransaction] {
        action.transactions.map { transaction in
            let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: action.amount)
            let feeAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: transaction.fee)

            let stakeKitTransaction = StakeKitTransaction(
                id: transaction.id,
                amount: amount,
                fee: Fee(feeAmount),
                unsignedData: transaction.unsignedTransactionData,
                params: StakeKitTransactionParams(validator: action.validator)
            )

            return stakeKitTransaction
        }
    }
}
