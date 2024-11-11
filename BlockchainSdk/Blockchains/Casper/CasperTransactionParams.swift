//
//  CasperTransactionParams.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct CasperTransactionParams: TransactionParams {
    let memo: UInt64

    public init(memo: UInt64) {
        self.memo = memo
    }
}
