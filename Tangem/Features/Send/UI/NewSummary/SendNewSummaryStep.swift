//
//  SendNewSummaryStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendNewSummaryStep {
    private let viewModel: SendNewSummaryViewModel
    private let interactor: SendNewSummaryInteractor
    private let analyticsLogger: SendSummaryAnalyticsLogger
    private let sendFeeProvider: SendFeeProvider

    init(
        viewModel: SendNewSummaryViewModel,
        interactor: SendNewSummaryInteractor,
        analyticsLogger: SendSummaryAnalyticsLogger,
        sendFeeProvider: SendFeeProvider
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

extension SendNewSummaryStep: SendStep {
    var type: SendStepType { .newSummary(viewModel) }
    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

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
