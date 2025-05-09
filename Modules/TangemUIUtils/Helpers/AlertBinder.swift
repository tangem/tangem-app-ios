//
//  AlertBinder.swift
//  TangemUIUtils
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemLocalization

public struct AlertBinder: Identifiable {
    public let id = UUID()

    public let alert: Alert

    public init(alert: Alert) {
        self.alert = alert
    }

    public init(title: String, message: String) {
        alert = Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: Alert.Button.default(Text(Localization.commonOk))
        )
    }
}
