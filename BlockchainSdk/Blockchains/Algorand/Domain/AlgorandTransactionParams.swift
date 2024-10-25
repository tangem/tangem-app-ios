//
//  AlgorandTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// This model describe parameters from external application
public struct AlgorandTransactionParams: TransactionParams {
    let nonce: String

    public init(nonce: String) {
        self.nonce = nonce
    }
}
