//
//  SendError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct SendError: Error, BindableError {
    private let error: Error
    private let openMailAction: (Error) -> Void

    init(_ error: Error, openMailAction: @escaping (Error) -> Void) {
        self.error = error
        self.openMailAction = openMailAction
    }

    var alertBinder: AlertBinder {
        let errorDescription = String(error.localizedDescription.dropTrailingPeriod)

        let alert = Alert(title: Text(Localization.feedbackSubjectTxFailed),
                          message: Text(Localization.alertFailedToSendTransactionMessage(errorDescription)),
                          primaryButton: .default(Text(Localization.alertButtonRequestSupport), action: { openMailAction(error) }),
                          secondaryButton: .default(Text(Localization.commonCancel)))

        return AlertBinder(alert: alert)
    }
}
