//
//  AlertBinder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ActionSheetBinder: Identifiable {
    let id = UUID()
    let sheet: ActionSheet

    init(sheet: ActionSheet) {
        self.sheet = sheet
    }
}

struct AlertBinder: Identifiable {
    let id = UUID()
    let alert: Alert
    var error: Error?

    init(alert: Alert, error: Error? = nil) {
        self.alert = alert
        self.error = error
    }

    init(title: String, message: String, error: Error? = nil) {
        self.alert = Alert(title: Text(title),
                           message: Text(message),
                           dismissButton: Alert.Button.default(Text("common_ok".localized)))
        self.error = error
    }
}

enum AlertBuilder {
    static var successTitle: String {
        "common_success".localized
    }

    static var warningTitle: String {
        "common_warning".localized
    }

    static var okButtonTitle: String { "common_ok".localized }

    static func makeSuccessAlert(message: String, okAction: @escaping (() -> Void) = { }) -> AlertBinder {
        .init(alert: Alert(title: Text(successTitle),
                           message: Text(message),
                           dismissButton: Alert.Button.default(Text(okButtonTitle), action: okAction)))
    }

    static func makeSuccessAlertController(message: String, okAction: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: successTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButtonTitle, style: .default, handler: { _ in okAction?() }))
        return alert
    }

    static func makeOkGotItAlert(message: String, okAction: @escaping (() -> Void) = { }) -> AlertBinder {
        .init(alert: Alert(title: Text(warningTitle),
                           message: Text(message),
                           dismissButton: .default(Text("warning_button_ok"), action: okAction)))
    }

    static func makeOkGotItAlertController(message: String, okAction: @escaping (() -> Void) = { }) -> UIAlertController {
        let alert = UIAlertController(title: warningTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButtonTitle, style: .default, handler: { _ in okAction() }))
        return alert
    }

    static func makeOkErrorAlert(message: String, okAction: @escaping (() -> Void) = { }) -> AlertBinder {
        .init(alert: Alert(title: Text("common_error"),
                           message: Text(message),
                           dismissButton: .default(Text("warning_button_ok"), action: okAction)))
    }

    static func makeDemoAlert(_ message: String, okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(title: Text(warningTitle),
                           message: Text(message),
                           dismissButton: Alert.Button.default(Text(okButtonTitle), action: okAction)))
    }

    static func makeOldDeviceAlert() -> AlertBinder {
        .init(alert: Alert(title: Text(warningTitle),
                           message: Text("onboarding_alert_message_old_device"),
                           dismissButton: .default(Text("common_ok"), action: {})))
    }

    static func makeExitAlert(okAction: @escaping (() -> Void) = { }) -> AlertBinder {
        .init(alert: Alert(title: Text("onboarding_exit_alert_title"),
                           message: Text("onboarding_exit_alert_message"),
                           primaryButton: .default(Text("common_no"), action: {}),
                           secondaryButton: .destructive(Text("common_yes"), action: okAction)))
    }

    static func makeCardSettingsDeleteUserWalletAlert(
        rejectAction: @escaping (() -> Void),
        acceptAction: @escaping (() -> Void)
    ) -> AlertBinder {
        AlertBinder(
            alert: Alert(
                title: Text("card_settings_reset_card_delete_wallet_warning"),
                primaryButton: .default(Text("common_no"), action: rejectAction),
                secondaryButton: .destructive(Text("common_yes"), action: acceptAction)
            )
        )
    }
}
