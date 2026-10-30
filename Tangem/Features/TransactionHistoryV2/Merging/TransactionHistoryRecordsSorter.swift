//
//  TransactionHistoryRecordsSorter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum TransactionHistoryRecordsSorter {
    static func sorted(_ records: [TransactionRecord]) -> [TransactionRecord] {
        return records.sorted { lhs, rhs in
            let lhsDate = lhs.date ?? .distantFuture
            let rhsDate = rhs.date ?? .distantFuture
            if lhsDate != rhsDate {
                return lhsDate > rhsDate // timestamp (date) DESC
            }

            let lhsNonce = lhs.nonce ?? -1
            let rhsNonce = rhs.nonce ?? -1
            if lhsNonce != rhsNonce {
                return lhsNonce > rhsNonce // IFNULL(nonce, -1) DESC
            }

            if lhs.hash != rhs.hash {
                return lhs.hash < rhs.hash // hash ASC
            }

            return lhs.index < rhs.index // index ASC
        }
    }
}
