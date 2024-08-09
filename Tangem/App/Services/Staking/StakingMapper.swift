//
//  StakingMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemStaking

struct StakingMapper {
    private let amountTokenItem: TokenItem
    private let feeTokenItem: TokenItem

    init(amountTokenItem: TokenItem, feeTokenItem: TokenItem) {
        self.amountTokenItem = amountTokenItem
        self.feeTokenItem = feeTokenItem
    }

    func mapToStakeKitTransaction(transactionInfo: StakingTransactionInfo, value: Decimal) -> StakeKitTransaction {
        let amount = Amount(with: amountTokenItem.blockchain, type: amountTokenItem.amountType, value: value)
        let feeAmount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: transactionInfo.fee)

        let stakeKitTransaction = StakeKitTransaction(
            amount: amount,
            fee: Fee(feeAmount),
            sourceAddress: "",
            unsignedData: transactionInfo.unsignedTransactionData
        )

        return stakeKitTransaction
    }
}
