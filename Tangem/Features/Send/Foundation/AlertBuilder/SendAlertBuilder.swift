//
//  SendAlertBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import BlockchainSdk
import TangemLocalization
import struct TangemUIUtils.AlertBinder

protocol SendAlertBuilder {
    func makeTransactionFailedAlert(sendTxError: SendTxError, openMailAction: @escaping () -> Void) -> AlertBinder
    func makeDismissAlert(dismissAction: @escaping () -> Void) -> AlertBinder
    func makeFeeRetryAlert(retryAction: @escaping () -> Void) -> AlertBinder
    func makeCancelConvertingFlowAlert(action: @escaping () -> Void, cancel: @escaping () -> Void) -> AlertBinder
    func makeChangeTokenFlowAlert(action: @escaping () -> Void, cancel: @escaping () -> Void) -> AlertBinder
}

// MARK: Default

extension SendAlertBuilder {
    func makeTransactionFailedAlert(sendTxError: SendTxError, openMailAction: @escaping () -> Void) -> AlertBinder {
        let reason = String(sendTxError.localizedDescription.dropTrailingPeriod)
        return AlertBuilder.makeAlert(
            title: Localization.sendAlertTransactionFailedTitle,
            message: Localization.sendAlertTransactionFailedText(reason, sendTxError.errorCode),
            primaryButton: .default(Text(Localization.alertButtonRequestSupport), action: openMailAction),
            secondaryButton: .default(Text(Localization.commonCancel))
        )
    }

    func makeFeeRetryAlert(retryAction: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.sendFeeUnreachableErrorTitle,
            message: Localization.sendFeeUnreachableErrorText,
            primaryButton: .default(Text(Localization.commonRetry), action: retryAction),
            secondaryButton: .cancel()
        )
    }

    func makeChangeTokenFlowAlert(action: @escaping () -> Void, cancel: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.sendWithSwapChangeTokenAlertTitle,
            message: Localization.sendWithSwapChangeTokenAlertMessage,
            primaryButton: .default(Text(Localization.commonContinue), action: action),
            secondaryButton: .cancel(cancel)
        )
    }

    func makeCancelConvertingFlowAlert(action: @escaping () -> Void, cancel: @escaping () -> Void) -> AlertBinder {
        AlertBuilder.makeAlert(
            title: Localization.sendWithSwapRemoveConvertAlertTitle,
            message: Localization.sendWithSwapRemoveConvertAlertMessage,
            primaryButton: .default(Text(Localization.commonContinue), action: action),
            secondaryButton: .cancel()
        )
    }
}
