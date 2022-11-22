//
//  SaltPayRegistratorError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum SaltPayRegistratorError: String, Error, LocalizedError {
    case failedToMakeTxData
    case needPin
    case empty
    case noGas
    case emptyResponse
    case card
    case cardNotPassed
    case cardDisabled
    case emptyBackupCardScanned
    case weakPin
    case failedToBuildContract
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
            return .init(title: "saltpay_error_no_gas_title".localized,
                         message: "saltpay_error_no_gas_message".localized)
        default:
            return .init(alert: alert, error: self)
        }
    }
}

