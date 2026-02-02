//
//  TangemSdkAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import TangemSdk

final class TangemSdkAnalyticsLogger {
    func logHealthIfNeeded(_ card: Card) {
        guard let health = card.health, health != 0 else {
            return
        }

        Analytics.log(event: .cardHealth, params: [
            .cardId: card.cardId,
            .health: "\(health)",
            .batch: card.batchId,
            .firmware: card.firmwareVersion.stringValue,
        ])
    }
}
