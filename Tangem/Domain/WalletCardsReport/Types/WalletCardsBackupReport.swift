//
//  WalletCardsBackupReport.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import Foundation

/// The local backup-report store. Keyed by `cardId` rather than by wallet: upserting per physical card keeps
/// the store bounded, and the wallet a card belongs to lives on the card's `identity`.
struct WalletCardsBackupReport: Codable {
    var cards: [String: WalletCardsBackupCard]
    var pendingReports: [WalletCardsWaitingDeliveryBackupCards]
    var deliveredCardLinkedHashes: Set<String> = []

    static var empty: WalletCardsBackupReport {
        WalletCardsBackupReport(cards: [:], pendingReports: [])
    }
}

// MARK: - CustomStringConvertible

extension WalletCardsBackupReport: CustomStringConvertible {
    var description: String {
        return objectDescription("WalletCardsBackupReport", userInfo: [
            "cards": "\(cards.count)",
            "pendingReports": "\(pendingReports.count)",
        ])
    }
}
