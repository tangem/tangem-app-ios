//
//  CollectiblesBuybackTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CollectiblesBuybackTransaction: Equatable {
    let buybackID: String
    let memo: String
    let amount: Decimal
    let transaction: Data
}
