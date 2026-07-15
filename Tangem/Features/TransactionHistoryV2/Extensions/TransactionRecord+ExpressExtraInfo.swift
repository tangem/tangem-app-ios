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
        guard let extraInfo else {
            return nil
        }

        guard let expressExtraInfo = extraInfo as? TransactionHistoryExpressExtraInfo else {
            preconditionFailure("Unexpected extra info type: \(Swift.type(of: extraInfo))")
        }

        return expressExtraInfo
    }
}

extension TransactionRecord {
    func withExpressExtraInfo(_ extraInfo: TransactionHistoryExpressExtraInfo) -> TransactionRecord {
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
            nonce: nonce,
            extraInfo: extraInfo
        )
    }
}
