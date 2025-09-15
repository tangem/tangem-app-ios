//
//  OnrampStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import SwiftUI

class OnrampStep {
    private let tokenItem: TokenItem
    private let viewModel: OnrampViewModel
    private let interactor: OnrampInteractor

    init(
        tokenItem: TokenItem,
        viewModel: OnrampViewModel,
        interactor: OnrampInteractor
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

extension OnrampStep: SendStep {
    var shouldShowBottomOverlay: Bool { false }
    var type: SendStepType { .onramp(viewModel) }
    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher
    }
}
