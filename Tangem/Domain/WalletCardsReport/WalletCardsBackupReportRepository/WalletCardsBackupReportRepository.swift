//
//  WalletCardsBackupReportRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk

/// Local store of the latest known backup state of the user's cards.
protocol WalletCardsBackupReportRepository {
    /// Upserts a card's latest observed state under its own `cardId`, with `primaryCardId` grouping the
    /// ceremony's cards. The identity resolves in order: what the card revealed about itself, else the
    /// primary's stored identity (a backup card at linking), else `.blank` tagged with `primaryCardId` — and
    /// once that primary becomes `.filled`, the group's still-`.blank` cards are filled too.
    func store(card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError?)
}

// MARK: - DI

private struct WalletCardsBackupReportRepositoryInjectionKey: InjectionKey {
    static var currentValue: WalletCardsBackupReportRepository = CommonWalletCardsBackupReportRepository()
}

extension InjectedValues {
    var walletCardsBackupReportRepository: WalletCardsBackupReportRepository {
        get { Self[WalletCardsBackupReportRepositoryInjectionKey.self] }
        set { Self[WalletCardsBackupReportRepositoryInjectionKey.self] = newValue }
    }
}
