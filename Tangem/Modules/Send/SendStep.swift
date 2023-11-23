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
    case finish
}

extension SendStep {
    var name: String? {
        switch self {
        case .amount:
            return Localization.commonSend
        case .destination:
            return Localization.sendRecipient
        case .fee:
            return Localization.commonFeeSelectorTitle
        case .summary:
            return Localization.commonSend
        case .finish:
            return nil
        }
    }

    var hasNavigationButtons: Bool {
        switch self {
        case .amount, .destination, .fee:
            return true
        case .summary, .finish:
            return false
        }
    }
}
