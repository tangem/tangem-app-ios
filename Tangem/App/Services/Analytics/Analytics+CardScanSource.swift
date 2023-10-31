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
        case main
        case mainUnlock
        case myWalletsNewCard
        case myWalletsUnlock
        case settings

        var cardScanButtonEvent: Analytics.Event {
            switch self {
            case .welcome:
                return .introductionProcessButtonScanCard
            case .auth:
                return .buttonCardSignIn
            case .main:
                return .buttonScanCard
            case .myWalletsNewCard:
                return .myWalletsButtonScanNewCardMyWallets
            case .myWalletsUnlock:
                return .walletUnlockTapped
            case .settings:
                return .buttonScanNewCardSettings
            case .mainUnlock:
                return .buttonUnlockWithCardScan
            }
        }

        var cardWasScannedParameterValue: Analytics.ParameterValue {
            switch self {
            case .welcome:
                return .scanSourceWelcome
            case .auth:
                return .scanSourceAuth
            case .main, .mainUnlock:
                return .scanSourceMain
            case .myWalletsNewCard, .myWalletsUnlock:
                return .scanSourceMyWallets
            case .settings:
                return .scanSourceSettings
            }
        }
    }
}

extension Analytics {
    enum CommonSource: String {
        case main
        case token

        var parameterValue: String {
            return rawValue.capitalizingFirstLetter()
        }
    }
}
