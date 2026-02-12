//
//  SwapSummaryStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SwapSummaryStep {
    private let viewModel: SendSummaryViewModel
    private let interactor: SendSummaryInteractor
    private let analyticsLogger: SendSummaryAnalyticsLogger
    private let sendFeeProvider: SendFeeUpdater

    init(
        viewModel: SendSummaryViewModel,
        interactor: SendSummaryInteractor,
        analyticsLogger: SendSummaryAnalyticsLogger,
        sendFeeProvider: SendFeeUpdater
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
        self.sendFeeProvider = sendFeeProvider
    }

    func set(router: SendSummaryStepsRoutable) {
        viewModel.router = router
    }
}

// MARK: - SendStep

extension SwapSummaryStep: SendStep {
    var type: SendStepType { .summary(viewModel) }

    var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        interactor.isUpdatingPublisher.eraseToAnyPublisher()
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isReadyToSendPublisher.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        analyticsLogger.logSummaryStepOpened()
        sendFeeProvider.updateFees()
    }
}
