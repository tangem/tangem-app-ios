//
//  TransactionRecord+ExtraInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension TransactionRecord {
    enum TransactionRecordExtraInfo {
        // [REDACTED_TODO_COMMENT]
    }
}

extension TransactionRecord {
    // [REDACTED_TODO_COMMENT]
    var extraInfo: TransactionRecordExtraInfo? {
        _extraInfo as? TransactionRecordExtraInfo
    }
}

extension TransactionRecord {
    func withExtraInfo(_ extraInfo: TransactionRecordExtraInfo?) -> TransactionRecord {
        return TransactionRecord(
            hash: hash,
            index: index,
            source: source,
            destination: destination,
            fee: fee,
            status: status,
            isOutgoing: isOutgoing,
            type: type,
            date: date,
            tokenTransfers: tokenTransfers,
            isFromYieldContract: isFromYieldContract,
            extraInfo: extraInfo
        )
    }
}
