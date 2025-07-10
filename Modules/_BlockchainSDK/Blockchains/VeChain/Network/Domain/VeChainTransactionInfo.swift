//
//  VeChainTransactionInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct VeChainTransactionInfo {
    /// Already processed transactions have a non-nil `transactionHash`,
    /// while pending and not-existing transactions have a nil value for the `transactionHash`.
    ///
    /// - Warning: VeChain's API doesn't provide the status (like `reverted`, etc) of the transaction.
    let transactionHash: String?
}
