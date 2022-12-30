//
//  SaltPayRegistratorError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum SaltPayRegistratorError: String, Error, LocalizedError {
    case failedToMakeTxData
    case needPin
    case empty
    case noGas
    case emptyResponse
    case cardNotPassed
    case cardDisabled
    case emptyBackupCardScanned
    case weakPin
    case failedToParseAllowance
    case missingClaimableAmount
    case blockchainError

    var errorDescription: String? {
        self.rawValue
    }

    var alertBinder: AlertBinder {
        switch self {
        case .weakPin:
            return .init(title: "saltpay_error_pin_weak_title".localized,
                         message: "saltpay_error_pin_weak_message".localized)
        case .emptyBackupCardScanned:
            return .init(title: "saltpay_error_empty_backup_title".localized,
                         message: "saltpay_error_empty_backup_message".localized)
        case .noGas:
            let alert = Alert(title: Text("saltpay_error_no_gas_title"),
                              message: Text("saltpay_error_no_gas_message"),
                              primaryButton: Alert.Button.default(Text("details_chat"), action: { AppPresenter.shared.showChat() }),
                              secondaryButton: Alert.Button.default(Text("common_ok")))

            return .init(alert: alert)
        case .cardNotPassed, .cardDisabled, .failedToParseAllowance, .blockchainError:
            let alert = Alert(title: Text("common_error"),
                              message: Text(errorDescription ?? ""),
                              primaryButton: Alert.Button.default(Text("details_chat"), action: { AppPresenter.shared.showChat() }),
                              secondaryButton: Alert.Button.default(Text("common_ok")))

            return .init(alert: alert)
        default:
            return .init(alert: alert, error: self)
        }
    }
}

