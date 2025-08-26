//
//  AnalyticsEvent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension Analytics {
    enum CardScanSource {
        case welcome
        case auth
        case mainUnlock
        case settings
        case createWallet
        case importWallet

        var cardScanButtonEvent: Analytics.Event {
            switch self {
            case .welcome, .createWallet, .importWallet:
                return .introductionProcessButtonScanCard
            case .auth:
                return .buttonCardSignIn
            case .settings:
                return .buttonScanNewCardSettings
            case .mainUnlock:
                return .buttonUnlockWithCardScan
            }
        }

        var cardWasScannedParameterValue: Analytics.ParameterValue {
            switch self {
            case .welcome:
                return .introduction
            case .auth:
                return .signIn
            case .mainUnlock:
                return .main
            case .settings:
                return .settings
            case .createWallet:
                return .createWallet
            case .importWallet:
                return .importWallet
            }
        }
    }
}
