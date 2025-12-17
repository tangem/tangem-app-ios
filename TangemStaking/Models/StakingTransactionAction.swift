//
//  StakingTransactionAction.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct StakingTransactionAction: Hashable {
    public let id: String?
    public let amount: Decimal
    public let target: String?
    public let transactions: [StakingTransactionInfo]

    public init(id: String? = nil, amount: Decimal, target: String? = nil, transactions: [StakingTransactionInfo]) {
        self.id = id
        self.amount = amount
        self.transactions = transactions
        self.target = target
    }
}
