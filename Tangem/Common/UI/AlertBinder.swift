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
                           dismissButton: Alert.Button.default(Text(L10n.commonOk)))
        self.error = error
    }
}

enum AlertBuilder {
    static var successTitle: String {
        L10n.commonSuccess
    }

    static var warningTitle: String {
        L10n.commonWarning
    }

    static var okButtonTitle: String { L10n.commonOk }

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
                           dismissButton: .default(Text(L10n.warningButtonOk), action: okAction)))
    }

    static func makeOkGotItAlertController(message: String, okAction: @escaping (() -> Void) = { }) -> UIAlertController {
        let alert = UIAlertController(title: warningTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButtonTitle, style: .default, handler: { _ in okAction() }))
        return alert
    }

    static func makeOkErrorAlert(message: String, okAction: @escaping (() -> Void) = { }) -> AlertBinder {
        .init(alert: Alert(title: Text(L10n.commonError),
                           message: Text(message),
                           dismissButton: .default(Text(L10n.warningButtonOk), action: okAction)))
    }

    static func makeDemoAlert(_ message: String, okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(title: Text(warningTitle),
                           message: Text(message),
                           dismissButton: Alert.Button.default(Text(okButtonTitle), action: okAction)))
    }

    static func makeOldDeviceAlert() -> AlertBinder {
        .init(alert: Alert(title: Text(warningTitle),
                           message: Text(L10n.onboardingAlertMessageOldDevice),
                           dismissButton: .default(Text(L10n.commonOk), action: {})))
    }

    static func makeExitAlert(okAction: @escaping (() -> Void) = { }) -> AlertBinder {
        .init(alert: Alert(title: Text(L10n.onboardingExitAlertTitle),
                           message: Text(L10n.onboardingExitAlertMessage),
                           primaryButton: .default(Text(L10n.commonNo), action: {}),
                           secondaryButton: .destructive(Text(L10n.commonYes), action: okAction)))
    }
}
