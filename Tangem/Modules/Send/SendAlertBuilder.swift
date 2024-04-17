//
//  SendAlertBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum SendAlertBuilder {
    static func makeDismissalConfirmationAlert(callback: @escaping () -> Void) -> AlertBinder {
        let confirmationButton = Alert.Button.default(Text(Localization.commonOk), action: callback)
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendCloseConfirmationMessage,
            primaryButton: confirmationButton,
            secondaryButton: .cancel()
        )
    }

    static func makeFeeRetryAlert(retryAction: @escaping () -> Void) -> AlertBinder {
        let retryButton = Alert.Button.default(Text(Localization.commonRetry), action: retryAction)
        return AlertBuilder.makeAlert(
            title: Localization.sendFeeUnreachableErrorTitle,
            message: Localization.sendFeeUnreachableErrorText,
            primaryButton: retryButton,
            secondaryButton: .cancel()
        )
    }

    static func makeSubtractFeeFromMaxAmountAlert(subtractAction: @escaping () -> Void) -> AlertBinder {
        let subtractButton = Alert.Button.default(Text(Localization.sendAlertFeeCoverageSubractText), action: subtractAction)
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendAlertFeeCoverageTitle,
            primaryButton: subtractButton,
            secondaryButton: .cancel()
        )
    }

    static func makeCustomFeeTooLowAlert(continueAction: @escaping () -> Void) -> AlertBinder {
        let continueButton = Alert.Button.default(Text(Localization.commonContinue), action: continueAction)
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendAlertFeeTooLowText,
            primaryButton: continueButton,
            secondaryButton: .cancel()
        )
    }

    static func makeCustomFeeTooHighAlert(_ orderOfMagnitude: Int, continueAction: @escaping () -> Void) -> AlertBinder {
        let continueButton = Alert.Button.default(Text(Localization.commonContinue), action: continueAction)
        return AlertBuilder.makeAlert(
            title: "",
            message: Localization.sendAlertFeeTooHighText(orderOfMagnitude),
            primaryButton: continueButton,
            secondaryButton: .cancel()
        )
    }
}
