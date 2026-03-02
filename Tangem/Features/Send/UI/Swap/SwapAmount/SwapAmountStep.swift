//
//  SwapAmountStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class SwapAmountStep {
    private let viewModel: SwapAmountViewModel
    private let interactor: SendAmountInteractor
    private let interactorSaver: SendAmountInteractorSaver
    private let analyticsLogger: SendAmountAnalyticsLogger

    init(
        viewModel: SwapAmountViewModel,
        interactor: SendAmountInteractor,
        interactorSaver: SendAmountInteractorSaver,
        analyticsLogger: SendAmountAnalyticsLogger
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.interactorSaver = interactorSaver
        self.analyticsLogger = analyticsLogger
    }

    func set(router: SwapAmountCompactRoutable) {
        viewModel.router = router
    }

    func cancelChanges() {
        interactorSaver.cancelChanges()
    }
}

// MARK: - SendStep

extension SwapAmountStep: SendStep {
    var type: SendStepType { .swapAmount(viewModel) }

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
