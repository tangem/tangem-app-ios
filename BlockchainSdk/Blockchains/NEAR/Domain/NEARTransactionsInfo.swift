//
//  NEARTransactionsInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct NEARTransactionsInfo {
    enum Status {
        case success
        case failure
        case other
    }

    struct Transaction {
        let result: TransactionSendResult
        let status: Status
    }

    let transactions: [Transaction]
}

// MARK: - Convenience extensions

extension NEARTransactionsInfo.Transaction {
    init(hash: String, status: NEARTransactionsInfo.Status, currentProviderHost: String) {
        self.init(
            result: .init(hash: hash, currentProviderHost: currentProviderHost),
            status: status
        )
    }
}
