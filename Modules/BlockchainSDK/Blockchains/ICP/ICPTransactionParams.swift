//
//  ICPTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ICPTransactionParams: TransactionParams {
    var memo: UInt64

    public init(memo: UInt64) {
        self.memo = memo
    }
}
