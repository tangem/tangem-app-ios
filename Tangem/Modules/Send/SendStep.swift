//
//  SendStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum SendStep {
    case amount
    case destination
    case fee
    case summary
}

extension SendStep {
    #warning("L10n")
    var name: String {
        switch self {
        case .amount:
            return "Send"
        case .destination:
            return "Recipient"
        case .fee:
            return "Speed and Fee"
        case .summary:
            return "Send"
        }
    }

    var hasNavigationButtons: Bool {
        switch self {
        case .amount, .destination, .fee:
            return true
        case .summary:
            return false
        }
    }
}
