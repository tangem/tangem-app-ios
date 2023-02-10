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
        case myWallets

        var cardScanButtonEvent: Analytics.Event {
            switch self {
            case .welcome:
                return .introductionProcessButtonScanCard
            case .auth:
                return .buttonCardSignIn
            case .main:
                return .buttonScanCard
            case .myWallets:
                return .buttonScanNewCard
            }
        }

        var cardDidScanEvent: Analytics.Event {
            switch self {
            case .welcome:
                return .introductionProcessCardWasScanned
            case .auth:
                return .signInCardWasScanned
            case .main:
                return .mainCardWasScanned
            case .myWallets:
                return .myWalletsCardWasScanned
            }
        }
    }
}
