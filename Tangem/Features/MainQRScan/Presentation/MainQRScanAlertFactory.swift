//
//  MainQRScanAlertFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUIUtils

struct MainQRScanAlertFactory {
    func makeUnrecognizedAlert(onDismiss: @escaping () -> Void) -> AlertBinder {
        AlertBinder(
            alert: Alert(
                title: Text(Localization.qrScannerErrorUnrecognizedTitle),
                message: Text(Localization.qrScannerErrorUnrecognizedMessage),
                dismissButton: .default(Text(Localization.commonOk), action: onDismiss)
            )
        )
    }

    func makeNoSupportedTokensAlert(onDismiss: @escaping () -> Void) -> AlertBinder {
        AlertBinder(
            alert: Alert(
                title: Text(Localization.qrScannerErrorUnsupportedNetworkTitle),
                message: Text(Localization.qrScannerErrorUnsupportedNetworkMessage),
                dismissButton: .default(Text(Localization.commonOk), action: onDismiss)
            )
        )
    }

    func makeUnknownParametersAlert(
        parameterNames: String,
        onContinue: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> AlertBinder {
        return AlertBinder(
            alert: Alert(
                title: Text(Localization.qrScannerWarningUnknownParametersTitle),
                message: Text(Localization.qrScannerWarningUnknownParametersMessage(parameterNames)),
                primaryButton: .default(Text(Localization.commonContinue), action: onContinue),
                secondaryButton: .cancel(Text(Localization.commonCancel), action: onCancel)
            )
        )
    }

    func makeSelfAddressAlert(onDismiss: @escaping () -> Void) -> AlertBinder {
        AlertBinder(
            alert: Alert(
                title: Text(Localization.commonError),
                message: Text(Localization.sendErrorAddressSameAsWallet),
                dismissButton: .default(Text(Localization.commonOk), action: onDismiss)
            )
        )
    }
}
