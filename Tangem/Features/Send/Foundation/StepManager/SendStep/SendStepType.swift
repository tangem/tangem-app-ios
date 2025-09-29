//
//  SendStepType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum SendStepType {
    case destination(SendDestinationViewModel)
    case amount(SendAmountViewModel)
    case newAmount(SendNewAmountViewModel)
    case summary(SendSummaryViewModel)
    case newSummary(SendNewSummaryViewModel)
    case finish(SendFinishViewModel)
    case newFinish(SendNewFinishViewModel)
    case validators(StakingValidatorsViewModel)
    case onramp(OnrampViewModel)
    case newOnramp(NewOnrampViewModel)

    var isSummary: Bool {
        if case .summary = self {
            return true
        }

        if case .newSummary = self {
            return true
        }

        return false
    }

    var isFinish: Bool {
        if case .finish = self {
            return true
        }

        if case .newFinish = self {
            return true
        }

        return false
    }
}

// MARK: - Identifiable

extension SendStepType: Identifiable {
    var id: ObjectIdentifier {
        switch self {
        case .amount(let viewModel): viewModel.id
        case .newAmount(let viewModel): viewModel.id
        case .destination(let viewModel): viewModel.id
        case .validators(let viewModel): viewModel.id
        case .summary(let viewModel): viewModel.id
        case .newSummary(let viewModel): viewModel.id
        case .finish(let viewModel): viewModel.id
        case .newFinish(let viewModel): viewModel.id
        case .onramp(let viewModel): viewModel.id
        case .newOnramp(let viewModel): viewModel.id
        }
    }
}

// MARK: - Equatable

extension SendStepType: Equatable {
    static func == (lhs: SendStepType, rhs: SendStepType) -> Bool {
        lhs.id == rhs.id
    }
}

extension SendStepType {
    var analyticsSourceParameterValue: Analytics.ParameterValue {
        switch self {
        case .newAmount, .amount: .amount
        case .destination: .address
        case .validators: .stakeSourceValidators
        case .summary, .newSummary: .summary
        case .finish, .newFinish: .finish
        case .onramp, .newOnramp: .onramp
        }
    }
}
