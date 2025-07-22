//
//  SendFeeStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemLocalization
import struct TangemUIUtils.AlertBinder

class SendFeeStep {
    private let viewModel: SendFeeViewModel
    private let feeProvider: SendFeeProvider
    private let notificationManager: NotificationManager
    private let analyticsLogger: SendFeeAnalyticsLogger

    /// We have to use this `SendViewAlertPresenter`
    /// Because .alert(item:) doesn't work in the nested views
    private weak var alertPresenter: SendViewAlertPresenter?

    init(
        viewModel: SendFeeViewModel,
        feeProvider: SendFeeProvider,
        notificationManager: NotificationManager,
        analyticsLogger: SendFeeAnalyticsLogger,
    ) {
        self.viewModel = viewModel
        self.feeProvider = feeProvider
        self.notificationManager = notificationManager
        self.analyticsLogger = analyticsLogger
    }

    func set(alertPresenter: SendViewAlertPresenter) {
        self.alertPresenter = alertPresenter
    }
}

// MARK: - SendStep

extension SendFeeStep: SendStep {
    var title: String? { Localization.commonFeeSelectorTitle }

    var type: SendStepType { .fee(viewModel) }

    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { .closeButton }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .none }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }

    func canBeClosed(continueAction: @escaping () -> Void) -> Bool {
        let events = notificationManager.notificationInputs.compactMap { $0.settings.event as? SendNotificationEvent }
        for event in events {
            switch event {
            case .customFeeTooLow:
                analyticsLogger.logSendNoticeTransactionDelaysArePossible()
                alertPresenter?.showAlert(
                    makeCustomFeeTooLowAlert(continueAction: continueAction)
                )

                return false
            case .customFeeTooHigh(let orderOfMagnitude):
                alertPresenter?.showAlert(
                    makeCustomFeeTooHighAlert(orderOfMagnitude, continueAction: continueAction)
                )

                return false
            default:
                break
            }
        }

        return true
    }

    func initialAppear() {
        analyticsLogger.logFeeStepOpened()
    }

    func willAppear(previous step: any SendStep) {
        feeProvider.updateFees()

        step.type.isSummary ? analyticsLogger.logFeeStepReopened() : analyticsLogger.logFeeStepOpened()
    }
}

// MARK: - Alert

extension SendFeeStep {
    func makeCustomFeeTooLowAlert(continueAction: @escaping () -> Void) -> AlertBinder {
        let continueButton = Alert.Button.default(Text(Localization.commonContinue), action: continueAction)
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendAlertFeeTooLowText,
            primaryButton: continueButton,
            secondaryButton: .cancel()
        )
    }

    func makeCustomFeeTooHighAlert(_ orderOfMagnitude: Int, continueAction: @escaping () -> Void) -> AlertBinder {
        let continueButton = Alert.Button.default(Text(Localization.commonContinue), action: continueAction)
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendAlertFeeTooHighText(orderOfMagnitude),
            primaryButton: continueButton,
            secondaryButton: .cancel()
        )
    }
}
