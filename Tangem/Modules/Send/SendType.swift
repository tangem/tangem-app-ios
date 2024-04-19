//
//  SendType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum SendType {
    case send
    case sell(amount: Amount, destination: String, tag: String?)
}

extension SendType {
    var steps: [SendStep] {
        switch self {
        case .send:
            return [.destination, .amount, .summary, .fee]
        case .sell:
            return [.summary, .fee]
        }
    }

    var predefinedAmount: Amount? {
        switch self {
        case .send:
            return nil
        case .sell(let amount, _, _):
            return amount
        }
    }

    var predefinedDestination: String? {
        switch self {
        case .send:
            return nil
        case .sell(_, let destination, _):
            return destination
        }
    }

    var predefinedTag: String? {
        switch self {
        case .send:
            return nil
        case .sell(_, let destination, _):
            return destination
        }
    }

    var canIncludeFeeIntoAmount: Bool {
        switch self {
        case .send:
            return true
        case .sell:
            return false
        }
    }
}
