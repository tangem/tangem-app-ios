//
//  PendingTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct PendingTransaction: Hashable, Identifiable {
    var id: Int { hashValue }
    
    enum Direction {
        case incoming
        case outgoing
    }
    let amountType: Amount.AmountType
    let destination: String
    let transferAmount: String
    let canBePushed: Bool
    let direction: Direction
}
