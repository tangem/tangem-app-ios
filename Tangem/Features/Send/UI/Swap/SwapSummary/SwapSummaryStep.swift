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
    private let viewModel: SwapSummaryViewModel
    private let interactor: SwapSummaryInteractor
    private let analyticsLogger: SendSummaryAnalyticsLogger

    init(
        viewModel: SwapSummaryViewModel,
        interactor: SwapSummaryInteractor,
        analyticsLogger: SendSummaryAnalyticsLogger,
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
    }

    func set(router: SwapSummaryStepRoutable) {
        viewModel.router = router
    }
}

// MARK: - SendStep

extension SwapSummaryStep: SendStep {
    var type: SendStepType { .swap(viewModel) }

    var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        interactor.isUpdatingPublisher.eraseToAnyPublisher()
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isReadyToSendPublisher.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        analyticsLogger.logSummaryStepOpened()
    }
}
