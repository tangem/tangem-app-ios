//
//  TransactionHistoryExtraInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum TransactionHistoryExtraInfo: TransactionRecord.ExtraInfo, Hashable {
    case express(TransactionHistoryExpressExtraInfo)

    var groupingId: String {
        switch self {
        case .express(let info): info.txId
        }
    }
}
