//
//  WalletCardsWaitingDeliveryBackupCards.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// One wallet's cards awaiting delivery — the unit the back end accepts.
struct WalletCardsWaitingDeliveryBackupCards: Equatable {
    let userWalletId: String
    /// Carried alongside the cards because the back end takes it per wallet, and every card of a wallet
    /// reports the same value.
    let isImported: Bool
    let cards: [WalletCardsBackupCard]
}
