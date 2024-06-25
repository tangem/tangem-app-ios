//
//  SendStep.swift
//  Tangem
//
//  Created by Andrey Chukavin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

enum SendStep {
    case destination(viewModel: SendDestinationViewModel)
    case amount(viewModel: SendAmountViewModel)
    case fee(viewModel: SendFeeViewModel)
    case summary(viewModel: SendSummaryViewModel)
    case finish(viewModel: SendFinishViewModel)

    func canBeOpen(next: SendStep) -> Bool {
        return true
    }

    func willBeOpen(previous step: SendStep) {
        if case .summary(let viewModel) = self {
            viewModel.setupAnimations(previousStep: step)
        }
    }
}

extension SendStep {
    func name(currencyName: String) -> String? {
        switch self {
        case .amount:
            return Localization.sendAmountLabel
        case .destination:
            return Localization.sendRecipientLabel
        case .fee:
            return Localization.commonFeeSelectorTitle
        case .summary:
            return Localization.sendSummaryTitle(currencyName)
        case .finish:
            return nil
        }
    }

    func description(walletName: String) -> String? {
        if case .summary = self {
            return walletName
        } else {
            return nil
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
