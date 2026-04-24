//
//  CardanoUnspentOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct CardanoUnspentOutput: Hashable {
    let address: String
    let amount: UInt64
    let outputIndex: UInt64
    let transactionHash: String
    let assets: [Asset]
}

extension CardanoUnspentOutput {
    struct Asset: Hashable {
        let policyID: String
        /// Token/Asset symbol in hexadecimal format `ASCII` encoding e.g. `41474958 = AGIX`
        let assetNameHex: String
        let amount: UInt64
    }
}
