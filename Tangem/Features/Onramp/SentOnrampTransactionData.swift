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
    let paymentMethod: OnrampPaymentMethod
    let destinationTokenItem: TokenItem
    let destinationAddress: String
    let date: Date
    let fromAmount: Decimal
    let fromCurrencyCode: String
    let toAmount: Decimal?
    let countryCode: String
    let externalTxId: String?
    let externalTxUrl: String?
}
