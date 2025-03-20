//
//  SentOnrampTransactionData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemExpress

struct SentOnrampTransactionData {
    let txId: String
    let provider: ExpressProvider
    let destinationTokenItem: TokenItem
    let date: Date
    let fromAmount: Decimal
    let fromCurrencyCode: String
    let externalTxId: String
}
