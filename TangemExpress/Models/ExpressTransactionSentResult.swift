//
//  ExpressTransactionSentResult.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ExpressTransactionSentResult {
    public let hash: String
    public let source: ExpressWallet
    public let data: ExpressTransactionData

    public init(
        hash: String,
        source: ExpressWallet,
        data: ExpressTransactionData
    ) {
        self.hash = hash
        self.source = source
        self.data = data
    }
}
