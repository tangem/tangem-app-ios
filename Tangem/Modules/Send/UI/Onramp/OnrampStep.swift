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
}

// MARK: - SendStep

extension OnrampStep: SendStep {
    var title: String? { "\(Localization.commonBuy) \(tokenItem.name)" }

    var type: SendStepType { .onramp(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var navigationTrailingViewType: SendStepNavigationTrailingViewType? {
        .dotsButton { [weak router = viewModel.onrampProvidersCompactViewModel.router] in
            router?.openOnrampSettingsView()
        }
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher
    }
}
