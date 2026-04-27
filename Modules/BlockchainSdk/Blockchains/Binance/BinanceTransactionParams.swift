//
//  BinanceTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct BinanceTransactionParams: TransactionParams {
    var memo: String?

    public init(memo: String? = nil) {
        self.memo = memo
    }
}
