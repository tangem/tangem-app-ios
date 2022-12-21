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
            return .init(title: L10n.saltpayErrorPinWeakTitle,
                         message: L10n.saltpayErrorPinWeakMessage)
        case .emptyBackupCardScanned:
            return .init(title: L10n.saltpayErrorEmptyBackupTitle,
                         message: L10n.saltpayErrorEmptyBackupMessage)
        case .noGas:
            let alert = Alert(title: Text(L10n.saltpayErrorNoGasTitle),
                              message: Text(L10n.saltpayErrorNoGasMessage),
                              primaryButton: Alert.Button.default(Text(L10n.detailsChat), action: { AppPresenter.shared.showChat() }),
                              secondaryButton: Alert.Button.default(Text(L10n.commonOk)))

            return .init(alert: alert)
        case .cardNotPassed, .cardDisabled, .failedToParseAllowance, .blockchainError:
            let alert = Alert(title: Text(L10n.commonError),
                              message: Text(errorDescription ?? ""),
                              primaryButton: Alert.Button.default(Text(L10n.detailsChat), action: { AppPresenter.shared.showChat() }),
                              secondaryButton: Alert.Button.default(Text(L10n.commonOk)))

            return .init(alert: alert)
        default:
            return .init(alert: alert, error: self)
        }
    }
}

