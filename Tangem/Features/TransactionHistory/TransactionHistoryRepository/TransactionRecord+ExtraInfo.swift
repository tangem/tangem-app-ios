//
//  TransactionRecord+ExtraInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

extension TransactionRecord {
    enum TransactionRecordExtraInfo {
        case exchange(ExchangeTransaction)
        case onramp(OnrampTransaction)
    }
}

extension TransactionRecord {
    var extraInfo: TransactionRecordExtraInfo? {
        guard let _extraInfo else {
            return nil
        }

        guard let extraInfo = _extraInfo as? TransactionRecordExtraInfo else {
            preconditionFailure("Unexpected extra info type: \(Swift.type(of: _extraInfo))")
        }

        return extraInfo
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
