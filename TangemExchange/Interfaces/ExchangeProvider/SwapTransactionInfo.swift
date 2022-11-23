//
//  SwapTransactionInfo.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct SwapTransactionInfo {
    let currency: Currency
    let destination: String
    let amount: Decimal
    let oneInchTxData: Data
}
