//
//  OnrampSummaryStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class OnrampSummaryStep {
    private let tokenItem: TokenItem
    private let viewModel: OnrampSummaryViewModel
    private let interactor: OnrampSummaryInteractor

    init(
        tokenItem: TokenItem,
        viewModel: OnrampSummaryViewModel,
        interactor: OnrampSummaryInteractor
    ) {
        self.tokenItem = tokenItem
        self.viewModel = viewModel
        self.interactor = interactor
    }

    func openOnrampSettingsView() {
        viewModel.openOnrampSettingsView()
    }

    func set(router: OnrampSummaryRoutable) {
        viewModel.router = router
        viewModel.onrampAmountViewModel.router = router
    }
}

// MARK: - SendStep

extension OnrampSummaryStep: SendStep {
    var shouldShowBottomOverlay: Bool { false }
    var type: SendStepType { .onramp(viewModel) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: false)
    }
}
