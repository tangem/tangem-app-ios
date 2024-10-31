//
//  StakingTransactionInfo+Mock.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

extension StakingTransactionAction {
    static let mock = StakingTransactionAction(
        id: UUID().uuidString,
        amount: 1.23,
        transactions: [.mock]
    )
}

extension StakingTransactionInfo {
    static let mock = StakingTransactionInfo(
        id: UUID().uuidString,
        actionId: UUID().uuidString,
        network: "solana",
        unsignedTransactionData: "",
        fee: 1.23
    )
}
