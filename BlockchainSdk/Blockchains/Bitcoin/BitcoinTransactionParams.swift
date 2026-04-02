//
//  BitcoinTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct BitcoinTransactionParams: TransactionParams {
    /// Raw memo bytes to be placed in `OP_RETURN` (max 80 bytes).
    public let memo: Data

    public init(memo: Data) {
        self.memo = memo
    }
}
