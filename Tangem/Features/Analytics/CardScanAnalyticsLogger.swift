//
//  CardScanAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CardScanAnalyticsLogger {
    func log(action: Analytics.CardScanAction, source: Analytics.CardScanSource) {
        let sourceParameterValue = parameterValue(source: source)

        let event: Analytics.Event = switch action {
        case .cardScanButton: cardScanButtonEvent(source: source)
        case .cardWasScanned: .cardWasScanned
        }

        Analytics.log(event, params: [.source: sourceParameterValue])
    }

    private func cardScanButtonEvent(source: Analytics.CardScanSource) -> Analytics.Event {
        switch source {
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

    private func parameterValue(source: Analytics.CardScanSource) -> Analytics.ParameterValue {
        switch source {
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
