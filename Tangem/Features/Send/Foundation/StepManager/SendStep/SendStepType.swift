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
    case summary(SendSummaryViewModel)
    case finish(SendFinishViewModel)
    case targets(StakingTargetsViewModel)
    case onramp(OnrampSummaryViewModel)

    var isSummary: Bool {
        if case .summary = self {
            return true
        }

        return false
    }

    var isFinish: Bool {
        if case .finish = self {
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
        case .destination(let viewModel): viewModel.id
        case .targets(let viewModel): viewModel.id
        case .summary(let viewModel): viewModel.id
        case .finish(let viewModel): viewModel.id
        case .onramp(let viewModel): viewModel.id
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
        case .amount: .amount
        case .destination: .address
        case .targets: .stakeSourceValidators
        case .summary: .summary
        case .finish: .finish
        case .onramp: .onramp
        }
    }
}
