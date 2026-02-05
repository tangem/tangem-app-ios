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

    init(
        viewModel: StakingTargetsViewModel,
        interactor: StakingTargetsInteractor
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
    }
}

// MARK: - SendStep

extension StakingTargetsStep: SendStep {
    var type: SendStepType { .targets(viewModel) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }
}
