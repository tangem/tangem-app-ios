//
//  BitcoinUnspentOutput.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(*, deprecated, message: "Used only for KASPA. Will be removed in https://tangem.atlassian.net/browse/[REDACTED_INFO]")
struct BitcoinUnspentOutput {
    let transactionHash: String
    let outputIndex: Int
    let amount: UInt64
    let outputScript: String
}
