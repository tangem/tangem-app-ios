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
    case sell(amount: Amount, destination: String)
}

extension SendType {
    var steps: [SendStep] {
        switch self {
        case .send:
            return [.destination, .amount, .fee, .summary]
        case .sell:
            return [.fee, .summary]
        }
    }

    var predefinedAmount: Amount? {
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

    var canIncludeFeeIntoAmount: Bool {
        switch self {
        case .send:
            return true
        case .sell:
            return false
        }
    }
}
