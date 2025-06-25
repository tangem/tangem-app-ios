//
//  SendNewAmountStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import SwiftUI

class SendNewAmountStep {
    private let viewModel: SendNewAmountViewModel
    private let interactor: SendAmountInteractor
    private let flowKind: SendModel.PredefinedValues.FlowKind

    init(
        viewModel: SendNewAmountViewModel,
        interactor: SendAmountInteractor,
        flowKind: SendModel.PredefinedValues.FlowKind
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.flowKind = flowKind
    }

    func set(router: SendNewAmountRoutable) {
        viewModel.router = router
    }
}

// MARK: - SendStep

extension SendNewAmountStep: SendStep {
    var title: String? { Localization.sendAmountLabel }

    var type: SendStepType { .newAmount(viewModel) }

    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { .none }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .closeButton }
    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher.eraseToAnyPublisher()
    }

    func initialAppear() {
        if case .staking = flowKind {
            Analytics.log(event: .stakingAmountScreenOpened, params: [.token: viewModel.tokenCurrencySymbol])
        }
    }

    // [REDACTED_TODO_COMMENT]
    func willAppear(previous step: any SendStep) {
        switch (flowKind, step.type.isSummary) {
        case (.staking, false):
            // Event has been sent in `initialAppear()`
            break
        case (.staking, true):
            let tokenCurrencySymbol = viewModel.tokenCurrencySymbol

            Analytics.log(
                event: .stakingScreenReopened,
                params: [
                    .source: Analytics.ParameterValue.amount.rawValue,
                    .token: tokenCurrencySymbol,
                ]
            )
        case (_, true):
            Analytics.log(.sendScreenReopened, params: [.source: .amount])
        case (_, false):
            Analytics.log(.sendAmountScreenOpened)
        }
    }
}

// MARK: - Constants

extension SendNewAmountStep {
    enum Constants {
        static let amountMinTextScale = 0.5
        /// Fiat always has 2 fraction digits.
        static let fiatMaximumFractionDigits = 2
    }
}
