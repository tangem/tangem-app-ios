//
//  SendAmountStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine

class SendAmountStep {
    private let viewModel: SendAmountViewModel
    private let interactor: SendAmountInteractor
    private let interactorSaver: SendAmountInteractorSaver
    private let analyticsLogger: SendAmountAnalyticsLogger

    init(
        viewModel: SendAmountViewModel,
        interactor: SendAmountInteractor,
        interactorSaver: SendAmountInteractorSaver,
        analyticsLogger: SendAmountAnalyticsLogger,
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.interactorSaver = interactorSaver
        self.analyticsLogger = analyticsLogger
    }

    func set(router: SendAmountRoutable) {
        viewModel.router = router
    }

    func cancelChanges() {
        interactorSaver.cancelChanges()
    }
}

// MARK: - SendStep

extension SendAmountStep: SendStep {
    var type: SendStepType { .amount(viewModel) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher
    }

    func initialAppear() {
        analyticsLogger.logAmountStepOpened()
    }

    func willAppear(previous step: any SendStep) {
        step.type.isSummary ? analyticsLogger.logAmountStepReopened() : analyticsLogger.logAmountStepOpened()
        interactorSaver.captureValue()
    }
}

// MARK: - Constants

extension SendAmountStep {
    enum Constants {
        static let amountMinTextScale = 0.5
        /// Fiat always has 2 fraction digits.
        static let fiatMaximumFractionDigits = 2
    }
}
