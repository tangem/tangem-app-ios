//
//  TransactionRecord+DestinationAmount.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension TransactionRecord {
    var destinationAmountValue: Decimal {
        destination.destinations.reduce(0) { $0 + $1.amount }
    }
}
