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
}
