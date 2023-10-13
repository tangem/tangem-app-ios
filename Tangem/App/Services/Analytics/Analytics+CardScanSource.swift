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
                return .buttonScanNewCardMyWallets
            case .myWalletsUnlock:
                return .walletUnlockTapped
            case .settings:
                return .buttonScanNewCardSettings
            }
        }

        var cardWasScannedParameterValue: Analytics.ParameterValue {
            switch self {
            case .welcome:
                return .scanSourceWelcome
            case .auth:
                return .scanSourceAuth
            case .main:
                return .scanSourceMain
            case .myWalletsNewCard, .myWalletsUnlock:
                return .scanSourceMyWallets
            case .settings:
                return .scanSourceSettings
            }
        }
    }
}
