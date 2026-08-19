//
//  WalletCardsBackupReportRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemSdk

/// Local store of the latest known backup state of the user's cards.
protocol WalletCardsBackupReportRepository {
    /// Upserts a card's latest observed state under its own `cardId`, with `primaryCardId` grouping the
    /// ceremony's cards. The identity resolves in order: what the card revealed about itself, else the
    /// primary's stored identity (a backup card at linking), else `.blank` tagged with `primaryCardId` — and
    /// once that primary becomes `.filled`, the group's still-`.blank` cards are filled too.
    func store(card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError?)

    /// Cards the back end hasn't accepted yet — never delivered, or changed since they were — grouped into one
    /// entry per wallet. A `.blank` card has no wallet to be delivered under and stays out until its identity
    /// arrives. Emits the current state on subscription and after every change to the store.
    var pendingToDeliveryPublisher: AnyPublisher<[WalletCardsWaitingDeliveryBackupCards], Never> { get }

    /// Marks the cards the back end has just accepted, so they stop being reported as waiting.
    func markDelivered(report: WalletCardsWaitingDeliveryBackupCards)
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
