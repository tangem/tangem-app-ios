//
//  CardanoAddressResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct CardanoAddressResponse {
    let balance: UInt64
    let tokenBalances: [Token: Result<UInt64, Error>]
    let recentTransactionsHashes: [String]
    let unspentOutputs: [CardanoUnspentOutput]
}
