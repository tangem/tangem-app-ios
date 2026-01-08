//
//  StakingTargetsStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import SwiftUI

class StakingTargetsStep {
    private let viewModel: StakingTargetsViewModel
    private let interactor: StakingTargetsInteractor
    private let sendFeeProvider: TokenFeeProvider

    init(
        viewModel: StakingTargetsViewModel,
        interactor: StakingTargetsInteractor,
        sendFeeProvider: TokenFeeProvider
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeProvider = sendFeeProvider
    }
}

// MARK: - SendStep

extension StakingTargetsStep: SendStep {
    var type: SendStepType { .targets(viewModel) }

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
