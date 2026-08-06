//
//  WalletCardsBackupReportService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

let WalletCardsReporterLogger = AppLogger.tag("WalletCardsReporter")

/// Collects the latest known backup status of the user's cards from every source that observes them: the
/// backup ceremony and a card scan. For the ceremony, callers resolve the card's position (the role) so this
/// service stays free of the SDK state machine. The report is persisted locally and delivered to the back end
/// per wallet, once the wallet a card belongs to is known.
protocol WalletCardsBackupReportService: Initializable {
    /// Backup ceremony — a card was linked or finalized.
    func reportCard(_ card: WalletCardsCurrentlyProcessedCard, primaryCardId: String)

    /// Backup ceremony — a finalize step failed.
    func reportFailure(_ card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError)
}

extension WalletCardsBackupReportService {
    /// Backup ceremony — the primary card being set: seeds the report with the primary's record, which also
    /// becomes the group key for the ceremony's other cards. Its wallet id isn't always readable yet — a COS v8
    /// card withholds its keys until the backup is complete.
    func reportPrimaryCard(cardInfo: CardInfo) {
        let processed = WalletCardsCurrentlyProcessedCard(cardInfo: cardInfo, role: .primary)
        reportCard(processed, primaryCardId: cardInfo.card.cardId)
    }

    /// A card observed outside the ceremony — any scan in the app, including unlocking an existing wallet.
    func reportScannedCard(cardInfo: CardInfo) {
        // No ceremony primary to group under, so the card groups under itself.
        let processed = WalletCardsCurrentlyProcessedCard(cardInfo: cardInfo, role: nil)
        reportCard(processed, primaryCardId: cardInfo.card.cardId)
    }
}

extension InjectedValues {
    var walletCardsBackupReportService: WalletCardsBackupReportService {
        get { Self[WalletCardsBackupReportServiceInjectionKey.self] }
        set { Self[WalletCardsBackupReportServiceInjectionKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct WalletCardsBackupReportServiceInjectionKey: InjectionKey {
    static var currentValue: WalletCardsBackupReportService = {
        guard FeatureProvider.isAvailable(.walletCardsBackupReport) else {
            return DummyWalletCardsBackupReportService()
        }

        return CommonWalletCardsBackupReportService()
    }()
}

private struct DummyWalletCardsBackupReportService: WalletCardsBackupReportService {
    func initialize() {}
    func reportCard(_ card: WalletCardsCurrentlyProcessedCard, primaryCardId: String) {}
    func reportFailure(_ card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError) {}
}
