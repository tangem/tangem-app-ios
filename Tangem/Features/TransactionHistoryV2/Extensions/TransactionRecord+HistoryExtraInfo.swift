//
//  TransactionRecord+HistoryExtraInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension TransactionRecord {
    var historyExtraInfo: TransactionHistoryExtraInfo? {
        guard let extraInfo else {
            return nil
        }

        guard let historyExtraInfo = extraInfo as? TransactionHistoryExtraInfo else {
            preconditionFailure("Unexpected extra info type: \(Swift.type(of: extraInfo))")
        }

        return historyExtraInfo
    }

    func withHistoryExtraInfo(_ extraInfo: TransactionHistoryExtraInfo) -> TransactionRecord {
        TransactionRecord(
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
            isFolded: isFolded,
            nonce: nonce,
            extraInfo: extraInfo
        )
    }
}
