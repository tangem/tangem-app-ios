//
//  SendError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import BlockchainSdk

struct SendError: Error, BindableError {
    private let title: String
    private let message: String
    private let error: SendTxError

    private let openMailAction: (SendTxError) -> Void

    init(title: String, message: String, error: SendTxError, openMailAction: @escaping (SendTxError) -> Void) {
        self.title = title
        self.message = message
        self.error = error
        self.openMailAction = openMailAction
    }

    var alertBinder: AlertBinder {
        let alert = Alert(
            title: Text(title),
            message: Text(message),
            primaryButton: .default(Text(Localization.alertButtonRequestSupport), action: { openMailAction(error) }),
            secondaryButton: .default(Text(Localization.commonCancel))
        )

        return AlertBinder(alert: alert)
    }
}
