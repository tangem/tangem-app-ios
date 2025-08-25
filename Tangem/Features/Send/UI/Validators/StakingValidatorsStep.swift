//
//  StakingValidatorsStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import SwiftUI

class StakingValidatorsStep {
    private let viewModel: StakingValidatorsViewModel
    private let interactor: StakingValidatorsInteractor
    private let sendFeeProvider: SendFeeProvider

    init(
        viewModel: StakingValidatorsViewModel,
        interactor: StakingValidatorsInteractor,
        sendFeeProvider: SendFeeProvider
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeProvider = sendFeeProvider
    }
}

// MARK: - SendStep

extension StakingValidatorsStep: SendStep {
    var title: String? { Localization.stakingValidator }

    var type: SendStepType { .validators(viewModel) }

    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { .closeButton }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .none }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }

    func willDisappear(next step: SendStep) {
        guard step.type.isSummary else {
            return
        }

        sendFeeProvider.updateFees()
    }
}
