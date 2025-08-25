//
//  SendDestinationStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import SwiftUI

class SendDestinationStep {
    private let viewModel: SendDestinationViewModel
    private let interactor: SendDestinationInteractor
    private let sendFeeProvider: SendFeeProvider
    private let analyticsLogger: SendDestinationAnalyticsLogger

    init(
        viewModel: SendDestinationViewModel,
        interactor: any SendDestinationInteractor,
        sendFeeProvider: any SendFeeProvider,
        analyticsLogger: SendDestinationAnalyticsLogger
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeProvider = sendFeeProvider
        self.analyticsLogger = analyticsLogger
    }

    func set(stepRouter: SendDestinationStepRoutable) {
        viewModel.stepRouter = stepRouter
    }
}

// MARK: - SendStep

extension SendDestinationStep: SendStep {
    var title: String? { Localization.sendRecipientLabel }

    var type: SendStepType { .destination(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { .closeButton }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? {
        .qrCodeButton { [weak self] in
            self?.viewModel.scanQRCode()
        }
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.allFieldsIsValid.eraseToAnyPublisher()
    }

    func initialAppear() {
        analyticsLogger.logDestinationStepOpened()
    }

    func willAppear(previous step: any SendStep) {
        step.type.isSummary ? analyticsLogger.logDestinationStepReopened() : analyticsLogger.logDestinationStepOpened()
    }

    func willDisappear(next step: SendStep) {
        guard step.type.isSummary else {
            return
        }

        sendFeeProvider.updateFees()
    }
}
