//
//  AlertBinder.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

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
    static func makeSuccessAlert(message: String, okAction: (() -> Void)? = nil) -> Alert {
        Alert(title: Text("common_success"),
              message: Text(message),
              dismissButton: Alert.Button.default(Text("common_ok"), action: okAction))
    }
}
