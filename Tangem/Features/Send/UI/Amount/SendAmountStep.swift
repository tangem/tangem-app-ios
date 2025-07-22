//
//  SendAmountStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import SwiftUI

class SendAmountStep {
    private let viewModel: SendAmountViewModel
    private let interactor: SendAmountInteractor
    private let sendFeeProvider: SendFeeProvider
    private let analyticsLogger: SendAmountAnalyticsLogger

    init(
        viewModel: SendAmountViewModel,
        interactor: SendAmountInteractor,
        sendFeeProvider: any SendFeeProvider,
        analyticsLogger: SendAmountAnalyticsLogger
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeProvider = sendFeeProvider
        self.analyticsLogger = analyticsLogger
    }
}

// MARK: - SendStep

extension SendAmountStep: SendStep {
    var title: String? { Localization.sendAmountLabel }

    var type: SendStepType { .amount(viewModel) }

    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { .closeButton }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .none }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher.eraseToAnyPublisher()
    }

    func initialAppear() {
        analyticsLogger.logAmountStepOpened()
    }

    func willAppear(previous step: any SendStep) {
        step.type.isSummary ? analyticsLogger.logAmountStepReopened() : analyticsLogger.logAmountStepOpened()
    }

    func willDisappear(next step: SendStep) {
        guard step.type.isSummary else {
            return
        }

        sendFeeProvider.updateFees()
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
