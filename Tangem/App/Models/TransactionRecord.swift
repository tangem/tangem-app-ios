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
    let time: String
    var date: Date?
    let transferAmount: String
    let canBePushed: Bool
    let direction: Direction
    let status: Status
}

extension TransactionRecord {
    enum Direction {
        case incoming
        case outgoing

        var amountPrefix: String {
            switch self {
            case .incoming:
                return "+"
            case .outgoing:
                return "-"
            }
        }
    }

    enum Status {
        case inProgress
        case confirmed

        init(_ blockchainSdkStatus: TransactionStatus) {
            switch blockchainSdkStatus {
            case .confirmed:
                self = .confirmed
            case .unconfirmed:
                self = .inProgress
            }
        }

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
