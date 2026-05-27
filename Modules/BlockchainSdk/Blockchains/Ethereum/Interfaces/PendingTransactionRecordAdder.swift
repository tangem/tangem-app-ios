//
//  PendingTransactionRecordAdding.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PendingTransactionRecordAdding {
    func addPendingTransaction(_ transaction: Transaction, hash: String)
}
