//
//  SendSummaryStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendSummaryStep {
    private let viewModel: SendSummaryViewModel
    private let input: SendSummaryInput
    private let analyticsLogger: SendSummaryAnalyticsLogger

    init(
        viewModel: SendSummaryViewModel,
        input: SendSummaryInput,
        analyticsLogger: SendSummaryAnalyticsLogger
    ) {
        self.viewModel = viewModel
        self.input = input
        self.analyticsLogger = analyticsLogger
    }

    func set(router: SendSummaryStepsRoutable) {
        viewModel.router = router
    }
}

// MARK: - SendStep

extension SendSummaryStep: SendStep {
    var type: SendStepType { .summary(viewModel) }
    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        input.isReadyToSendPublisher.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        analyticsLogger.logSummaryStepOpened()
    }
}
