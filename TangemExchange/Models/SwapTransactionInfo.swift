//
//  SwapTransactionInfo.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct SwapTransactionInfo {
    public let currency: Currency
    public let destination: String
    public let amount: Decimal
    public let oneInchTxData: Data
}
