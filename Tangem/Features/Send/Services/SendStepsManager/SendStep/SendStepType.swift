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
    case newDestination(SendNewDestinationViewModel)
    case amount(SendAmountViewModel)
    case newAmount(SendNewAmountViewModel)
    case fee(SendFeeViewModel)
    case summary(SendSummaryViewModel)
    case newSummary(SendNewSummaryViewModel)
    case finish(SendFinishViewModel)
    case newFinish(SendNewFinishViewModel)
    case validators(StakingValidatorsViewModel)
    case onramp(OnrampViewModel)

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

extension SendStepType: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .amount(let viewModel): hasher.combine(viewModel.id)
        case .newAmount(let viewModel): hasher.combine(viewModel.id)
        case .destination(let viewModel): hasher.combine(viewModel.id)
        case .newDestination(let viewModel): hasher.combine(viewModel.id)
        case .fee(let viewModel): hasher.combine(viewModel.id)
        case .validators(let viewModel): hasher.combine(viewModel.id)
        case .summary(let viewModel): hasher.combine(viewModel.id)
        case .newSummary(let viewModel): hasher.combine(viewModel.id)
        case .finish(let viewModel): hasher.combine(viewModel.id)
        case .newFinish(let viewModel): hasher.combine(viewModel.id)
        case .onramp(let viewModel): hasher.combine(viewModel.id)
        }
    }

    static func == (lhs: SendStepType, rhs: SendStepType) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension SendStepType {
    var analyticsSourceParameterValue: Analytics.ParameterValue {
        switch self {
        case .newAmount, .amount: .amount
        case .destination, .newDestination: .address
        case .fee: .fee
        case .validators: .stakeSourceValidators
        case .summary, .newSummary: .summary
        case .finish, .newFinish: .finish
        case .onramp: .onramp
        }
    }
}
