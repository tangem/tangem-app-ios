//
//  PendingTransaction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

struct TransactionRecord: Hashable, Identifiable {
    var id: Int { hashValue }

    let amountType: Amount.AmountType
    let destination: String
    let dateTime: String
    let transferAmount: String
    let canBePushed: Bool
    let direction: Direction
    let status: Status
}

extension TransactionRecord {
    enum Direction {
        case incoming
        case outgoing
    }

    enum Status {
        case inProgress
        case confirmed

        var iconColor: Color {
            switch self {
            case .inProgress:
                return Colors.Icon.attention
            case .confirmed:
                return Colors.Icon.informative
            }
        }

        var textColor: Color {
            switch self {
            case .inProgress:
                return Colors.Text.attention
            case .confirmed:
                return Colors.Text.tertiary
            }
        }
    }
}
