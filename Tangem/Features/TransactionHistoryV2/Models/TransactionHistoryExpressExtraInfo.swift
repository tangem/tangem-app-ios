//
//  TransactionHistoryExpressExtraInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum TransactionHistoryExpressExtraInfo: TransactionRecord.ExtraInfo, Hashable {
    case exchange(ExchangeTransactionInfo)
    case onramp(OnrampTransactionInfo)

    var txId: String {
        switch self {
        case .exchange(let info): info.transaction.txId
        case .onramp(let info): info.transaction.txId
        }
    }
}
