//
//  TransactionHistoryPages.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// Use for indexed navigation state
struct TransactionHistoryIndexPage: Hashable {
    let number: Int
}

// Use for linked navigation state
struct TransactionHistoryLinkedPage: Hashable {
    let next: String?
}
