//
//  SaltPayRegistratorError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

enum SaltPayRegistratorError: String, Error, LocalizedError, BindableError {
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
            return .init(title: Localization.saltpayErrorPinWeakTitle,
                         message: Localization.saltpayErrorPinWeakMessage)
        case .emptyBackupCardScanned:
            return .init(title: Localization.saltpayErrorEmptyBackupTitle,
                         message: Localization.saltpayErrorEmptyBackupMessage)
        case .noGas:
            let alert = Alert(title: Text(Localization.saltpayErrorNoGasTitle),
                              message: Text(Localization.saltpayErrorNoGasMessage),
                              primaryButton: Alert.Button.default(Text(Localization.detailsChat), action: { AppPresenter.shared.showChat() }),
                              secondaryButton: Alert.Button.default(Text(Localization.commonOk)))

            return .init(alert: alert)
        case .cardNotPassed, .cardDisabled, .failedToParseAllowance, .blockchainError:
            let alert = Alert(title: Text(Localization.commonError),
                              message: Text(errorDescription ?? ""),
                              primaryButton: Alert.Button.default(Text(Localization.detailsChat), action: { AppPresenter.shared.showChat() }),
                              secondaryButton: Alert.Button.default(Text(Localization.commonOk)))

            return .init(alert: alert)
        default:
            return .init(alert: alert)
        }
    }
}

