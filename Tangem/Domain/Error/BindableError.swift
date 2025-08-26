//
//  BindableError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import TangemSdk
import TangemLocalization
import struct TangemUIUtils.AlertBinder

protocol BindableError {
    var binder: AlertBinder { get }
    func alertBinder(okAction: @escaping () -> Void) -> AlertBinder
}

// MARK: - Error + BindableError

extension Error {
    var alertBinder: AlertBinder {
        toBindable().binder
    }

    func alertBinder(okAction: @escaping () -> Void) -> AlertBinder {
        toBindable().alertBinder(okAction: okAction)
    }

    private func toBindable() -> BindableError {
        self as? BindableError ?? BindableErrorWrapper(self)
    }
}

private struct BindableErrorWrapper: BindableError {
    var binder: AlertBinder {
        alertBinder(okAction: {})
    }

    private let error: Error

    init(_ error: Error) {
        self.error = error
    }

    func alertBinder(okAction: @escaping () -> Void) -> AlertBinder {
        return AlertBinder(alert: Alert(
            title: Text(Localization.commonError),
            message: Text(error.localizedDescription),
            dismissButton: Alert.Button.default(Text(Localization.commonOk), action: okAction)
        ))
    }
}

// MARK: - TangemSdkError + BindableError

extension TangemSdkError: BindableError {
    var binder: AlertBinder {
        switch self {
        case .cardVerificationFailed:
            return AlertBinder(alert: Alert(
                title: Text(Localization.securityAlertTitle),
                message: Text(TangemSdkError.cardVerificationFailed.localizedDescription),
                primaryButton: Alert.Button.default(Text(Localization.alertButtonRequestSupport), action: {
                    openSupport()
                }),
                secondaryButton: Alert.Button.cancel(Text(Localization.commonCancel))
            ))
        default:
            return AlertBinder(alert: Alert(
                title: Text(Localization.commonError),
                message: Text(localizedDescription),
                dismissButton: Alert.Button.default(Text(Localization.commonOk))
            ))
        }
    }

    private func openSupport() {
        let logsComposer = LogsComposer(infoProvider: BaseDataCollector())
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.default.recipient,
            emailType: .attestationFailed
        )
        let mailView = MailView(viewModel: mailViewModel)
        let controller = UIHostingController(rootView: mailView)
        AppPresenter.shared.show(controller)
    }
}

// MARK: UserWalletRepositoryError + BindableError

enum UserWalletRepositoryError: String, Error, LocalizedError, BindableError {
    case duplicateWalletAdded
    case biometricsChanged
    case cardWithWrongUserWalletIdScanned
    case cantSelectWallet
    case cantUnlockWithCard
    case sensitiveInfoIsMissing

    var errorDescription: String? {
        rawValue
    }

    var binder: AlertBinder {
        switch self {
        case .duplicateWalletAdded:
            return .init(title: "", message: Localization.userWalletListErrorWalletAlreadySaved)
        case .biometricsChanged:
            return .init(title: Localization.commonAttention, message: Localization.keyInvalidatedWarningDescription)
        case .cardWithWrongUserWalletIdScanned:
            return .init(title: Localization.commonWarning, message: Localization.errorWrongWalletTapped)
        case .cantSelectWallet:
            return .init(title: "", message: Localization.genericErrorCode("cantSelectWallet"))
        case .cantUnlockWithCard:
            return .init(title: "", message: Localization.genericErrorCode("cantUnlockWithCard"))
        case .sensitiveInfoIsMissing:
            return .init(title: "", message: Localization.genericErrorCode("sensitiveInfoIsMissing"))
        }
    }
}
