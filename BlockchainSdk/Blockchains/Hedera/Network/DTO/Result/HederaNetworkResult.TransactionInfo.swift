//
//  HederaNetworkResult.TransactionInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import enum Hiero.Status

extension HederaNetworkResult {
    /// Used by the Consensus network layer.
    struct TransactionInfo {
        let status: Hiero.Status
        let hash: String
    }
}
