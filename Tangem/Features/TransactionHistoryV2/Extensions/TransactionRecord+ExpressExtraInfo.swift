//
//  TransactionRecord+ExpressExtraInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension TransactionRecord {
    var expressExtraInfo: TransactionHistoryExpressExtraInfo? {
        guard case .express(let expressExtraInfo) = historyExtraInfo else {
            return nil
        }

        return expressExtraInfo
    }
}

extension TransactionRecord {
    func withExpressExtraInfo(_ extraInfo: TransactionHistoryExpressExtraInfo) -> TransactionRecord {
        withHistoryExtraInfo(.express(extraInfo))
    }
}
