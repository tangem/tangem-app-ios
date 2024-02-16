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
    case finish(model: SendFinishViewModel)
}

extension SendStep {
    var name: String? {
        switch self {
        case .amount:
            return Localization.sendAmountLabel
        case .destination:
            return Localization.sendRecipientLabel
        case .fee:
            return Localization.commonFeeSelectorTitle
        case .summary:
            return Localization.sendConfirmLabel
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

    var opensKeyboardByDefault: Bool {
        switch self {
        case .amount:
            return true
        case .destination, .fee, .summary, .finish:
            return false
        }
    }
}

extension SendStep: Equatable {
    static func== (lhs: SendStep, rhs: SendStep) -> Bool {
        switch (lhs, rhs) {
        case (.amount, .amount):
            return true
        case (.destination, .destination):
            return true
        case (.fee, .fee):
            return true
        case (.summary, .summary):
            return true
        case (.finish, .finish):
            return true
        default:
            return false
        }
    }
}
