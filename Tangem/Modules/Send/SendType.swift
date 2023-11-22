//
//  SendType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum SendType {
    case send
    case sell(amount: Decimal, destination: String)
}

extension SendType {
    var steps: [SendStep] {
        switch self {
        case .send:
            return [.amount, .destination, .fee, .summary]
        case .sell:
            return [.fee, .summary]
        }
    }

    var predefinedAmount: Decimal? {
        switch self {
        case .send:
            return nil
        case .sell(let amount, _):
            return amount
        }
    }

    var predefinedDestination: String? {
        switch self {
        case .send:
            return nil
        case .sell(_, let destination):
            return destination
        }
    }
}
