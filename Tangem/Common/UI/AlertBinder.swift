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
}

enum AlertBuilder {
    static var successTitle: String {
        "common_success".localized
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
        .init(alert: Alert(title: Text("common_warning"),
                           message: Text(message),
                           dismissButton: .default(Text("warning_button_ok"), action: okAction)))
    }

    static func makeDemoAlert(okAction: @escaping (() -> Void) = {}) -> AlertBinder {
        .init(alert: Alert(title: Text("common_warning"),
                           message: Text("alert_demo_feature_disabled"),
                           dismissButton: Alert.Button.default(Text(okButtonTitle), action: okAction)))
    }

    static func makeOldDeviceAlert() -> AlertBinder {
        .init(alert: Alert(title: Text("common_warning"),
                           message: Text("onboarding_alert_message_old_device"),
                           dismissButton: .default(Text("common_ok"), action: {})))
    }
}
