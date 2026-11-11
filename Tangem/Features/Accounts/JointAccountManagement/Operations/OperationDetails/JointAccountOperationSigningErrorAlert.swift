//
//  JointAccountOperationSigningErrorAlert.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import struct TangemUIUtils.AlertBinder

struct JointAccountOperationSigningErrorAlert {
    private let kind: Kind
    private let onSupport: () -> Void

    init(error: Error, onSupport: @escaping () -> Void) {
        kind = Kind(error: error)
        self.onSupport = onSupport
    }

    var alertBinder: AlertBinder {
        switch kind {
        case .malicious:
            return AlertBuilder.makeAlertWithDefaultPrimaryButton(
                title: Localization.jointOperationMaliciousTitle,
                message: Localization.jointOperationMaliciousSubtitle,
                buttonText: Localization.commonClose
            )
        case .blocked:
            return AlertBuilder.makeAlert(
                title: Localization.jointOperationSigningBlockedTitle,
                message: Localization.jointOperationSigningBlockedSubtitle,
                primaryButton: .default(Text(Localization.commonSupport)) { onSupport() },
                secondaryButton: .cancel(Text(Localization.commonClose))
            )
        case .generic:
            return AlertBuilder.makeAlertWithDefaultPrimaryButton(
                title: Localization.commonSomethingWentWrong,
                message: Localization.accountGenericErrorDialogMessage,
                buttonText: Localization.commonOk
            )
        }
    }
}

// MARK: - Auxiliary types

private extension JointAccountOperationSigningErrorAlert {
    enum Kind {
        case malicious
        case blocked
        case generic

        init(error: Error) {
            switch error as? JointOperationError {
            case .maliciousOperation:
                self = .malicious
            case .unsupportedOperationForm, .operationVerificationFailed, .accountNotActive, .compositionMismatch:
                self = .blocked
            default:
                self = .generic
            }
        }
    }
}
