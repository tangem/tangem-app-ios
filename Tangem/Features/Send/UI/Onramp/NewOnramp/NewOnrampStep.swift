//
//  NewOnrampStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class NewOnrampStep {
    private let tokenItem: TokenItem
    private let viewModel: NewOnrampViewModel
    private let interactor: NewOnrampInteractor

    init(
        tokenItem: TokenItem,
        viewModel: NewOnrampViewModel,
        interactor: NewOnrampInteractor
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
    }
}

// MARK: - SendStep

extension NewOnrampStep: SendStep {
    var shouldShowBottomOverlay: Bool { false }
    var type: SendStepType { .newOnramp(viewModel) }
    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: false)
    }
}
