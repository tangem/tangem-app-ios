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

    init(alert: Alert) {
        self.alert = alert
    }

    init(title: String, message: String) {
        alert = Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: Alert.Button.default(Text(Localization.commonOk))
        )
    }
}

enum AlertBuilder {
    static var successTitle: String {
        Localization.commonSuccess
    }

    static var warningTitle: String {
        Localization.commonWarning
    }

    static var okButtonTitle: String { Localization.commonOk }

    static func makeSuccessAlert(message: String, okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(
            title: Text(successTitle),
            message: Text(message),
            dismissButton: Alert.Button.default(Text(okButtonTitle), action: okAction)
        ))
    }

    static func makeSuccessAlertController(message: String, okAction: (() -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: successTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButtonTitle, style: .default, handler: { _ in okAction?() }))
        return alert
    }

    static func makeOkGotItAlert(message: String, okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(
            title: Text(warningTitle),
            message: Text(message),
            dismissButton: .default(Text(Localization.warningButtonOk), action: okAction)
        ))
    }

    static func makeOkGotItAlertController(message: String, okAction: @escaping (() -> Void) = {}) -> UIAlertController {
        let alert = UIAlertController(title: warningTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButtonTitle, style: .default, handler: { _ in okAction() }))
        return alert
    }

    static func makeOkErrorAlert(message: String, okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(
            title: Text(Localization.commonError),
            message: Text(message),
            dismissButton: .default(Text(Localization.warningButtonOk), action: okAction)
        ))
    }

    static func makeDemoAlert(_ message: String, okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(
            title: Text(warningTitle),
            message: Text(message),
            dismissButton: Alert.Button.default(Text(okButtonTitle), action: okAction)
        ))
    }

    static func makeOldDeviceAlert() -> AlertBinder {
        .init(alert: Alert(
            title: Text(warningTitle),
            message: Text(Localization.onboardingAlertMessageOldDevice),
            dismissButton: .default(Text(Localization.commonOk), action: {})
        ))
    }

    static func makeExitAlert(okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(
            title: Text(Localization.onboardingExitAlertTitle),
            message: Text(Localization.onboardingExitAlertMessage),
            primaryButton: .default(Text(Localization.commonNo), action: {}),
            secondaryButton: .destructive(Text(Localization.commonYes), action: okAction)
        ))
    }

    static func makeAlert(title: String, message: String, primaryButton: Alert.Button, secondaryButton: Alert.Button?) -> AlertBinder {
        if let secondaryButton {
            return .init(alert: Alert(
                title: Text(title),
                message: Text(message),
                primaryButton: primaryButton,
                secondaryButton: secondaryButton
            ))
        } else {
            return .init(alert: Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: primaryButton
            ))
        }
    }
}
