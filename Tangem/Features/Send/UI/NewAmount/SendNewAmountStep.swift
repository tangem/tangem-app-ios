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

class SendNewAmountStep {
    private let viewModel: SendNewAmountViewModel
    private let interactor: SendNewAmountInteractor
    private let interactorSaver: SendNewAmountInteractorSaver
    private let analyticsLogger: SendAnalyticsLogger

    init(
        viewModel: SendNewAmountViewModel,
        interactor: SendNewAmountInteractor,
        interactorSaver: SendNewAmountInteractorSaver,
        analyticsLogger: SendAnalyticsLogger,
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.interactorSaver = interactorSaver
        self.analyticsLogger = analyticsLogger
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

    func saveChangesIfNeeded() {
        interactorSaver.save()
    }

    func initialAppear() {
        analyticsLogger.logAmountStepOpened()
    }

    func willAppear(previous step: any SendStep) {
        let isEditMode = step.type.isSummary

        isEditMode ? analyticsLogger.logAmountStepReopened() : analyticsLogger.logAmountStepOpened()
        interactorSaver.autosave(enabled: !isEditMode)
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
