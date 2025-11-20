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

    func mapToStakeKitTransactions(action: StakingTransactionAction) -> [StakingTransaction] {
        action.transactions.compactMap { transaction in
            let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: action.amount)
            let feeAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: transaction.fee)

            let params = StakeKitTransactionParams(
                type: .init(rawValue: transaction.type),
                status: .init(rawValue: transaction.status),
                stepIndex: transaction.stepIndex,
                validator: action.validator,
                solanaBlockhashDate: Date()
            )

            guard let unsignedTransactionData = transaction.unsignedTransactionData as? String else {
                return nil
            }

            let stakeKitTransaction = StakingTransaction(
                id: transaction.id,
                amount: amount,
                fee: Fee(feeAmount),
                unsignedData: unsignedTransactionData,
                params: params
            )

            return stakeKitTransaction
        }
    }

    func mapToP2PTransactions(action: StakingTransactionAction) -> [StakingTransaction] {
        action.transactions.compactMap { transaction -> StakingTransaction? in
            let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: action.amount)
            let feeAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: transaction.fee)

            guard let unsignedTransactionData = transaction.unsignedTransactionData as? EthereumCompiledTransaction else {
                return nil
            }

            let stakingTransaction = StakingTransaction(
                id: transaction.id,
                amount: amount,
                fee: Fee(feeAmount),
                unsignedData: unsignedTransactionData,
                params: nil
            )

            return stakingTransaction
        }
    }
}
