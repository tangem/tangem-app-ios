//
//  CosmosTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct CosmosTransactionParams: TransactionParams {
    let memo: String

    public init(memo: String) {
        self.memo = memo
    }
}
