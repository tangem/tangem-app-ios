//
//  CardanoAddressResponse.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct CardanoAddressResponse: Hashable {
    let balance: UInt64
    let tokenBalances: [Token: UInt64]
    let recentTransactionsHashes: [String]
    let unspentOutputs: [CardanoUnspentOutput]
}
