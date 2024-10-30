//
//  OnrampStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class OnrampStep {
    private let viewModel: OnrampViewModel
    private let interactor: OnrampInteractor

    init(
        viewModel: OnrampViewModel,
        interactor: OnrampInteractor
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
    }

    func setup(router: OnrampSummaryRoutable) {
        viewModel.router = router
    }
}

// MARK: - SendStep

extension OnrampStep: SendStep {
    var title: String? { Localization.stakingValidator }

    var type: SendStepType { .onramp(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher
    }
}
