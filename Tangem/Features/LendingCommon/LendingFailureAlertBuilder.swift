//
//  LendingFailureAlertBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk
import TangemLocalization
import struct TangemUIUtils.AlertBinder

struct LendingFailureAlertBuilder {
    let failureMessage: String

    private let sendAlertBuilder: SendAlertBuilder = CommonSendAlertBuilder()

    func makeAlert(
        for error: TransactionDispatcherResult.Error,
        retryFee: @escaping () -> Void,
        openSupport: @escaping (TransactionDispatcherTransactionType, SendTxError) -> Void
    ) -> AlertBinder? {
        switch error {
        case .userCancelled, .transactionNotFound, .feeNotFound, .actionNotSupported:
            return nil
        case .informationRelevanceServiceError:
            return sendAlertBuilder.makeFeeRetryAlert(retryAction: retryFee)
        case .informationRelevanceServiceFeeWasIncreased:
            return AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle)
        case .sendTxError(let transaction, let sendTxError):
            return makeFailureAlert { openSupport(transaction, sendTxError) }
        case .loadTransactionInfo(let error):
            return error.alertBinder
        case .demoAlert:
            return AlertBuilder.makeDemoAlert()
        }
    }

    private func makeFailureAlert(supportAction: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.commonSomethingWentWrong,
            message: failureMessage,
            primaryButton: .default(Text(Localization.commonSupport), action: supportAction),
            secondaryButton: .cancel(Text(Localization.commonClose))
        )
    }
}
