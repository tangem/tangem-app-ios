//
//  OnrampTransaction.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampTransaction {
    public let fromAmount: Decimal
    public let toAmount: Decimal?
    public let status: OnrampTransactionStatus
    public let externatTxURL: String?
}
