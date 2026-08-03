//
//  WalletCardsCurrentlyProcessedCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

/// A snapshot of a card as observed at report time — the service's input to the repository. `role`,
/// `identity` and `backupStatus` are `nil` when the card doesn't reveal them; `identity` is never `.blank`,
/// which only the repository mints — a `.blank` arriving from here would never be promoted.
struct WalletCardsCurrentlyProcessedCard {
    let cardId: String
    let cardPublicKey: Data
    let role: WalletCardsBackupCard.Role?
    let identity: WalletCardsBackupCard.Identity?
    let curves: [EllipticCurve]
    let backupStatus: WalletCardsBackupCard.BackupStatus?
}

extension WalletCardsCurrentlyProcessedCard {
    /// A card returned by a completed SDK step (linked or finalized); the role comes from
    /// `BackupService.role(for:)`. Wrapped into a `CardInfo` so that the wallet id always comes from the same
    /// place — the wallet config — rather than from the card's first key. `walletData` isn't available here and
    /// isn't needed: the cards that go through this ceremony are never the combined-seed kind that depends on
    /// it.
    init(card: Card, role: WalletCardsBackupCard.Role?) {
        let cardInfo = CardInfo(card: CardDTO(card: card), walletData: .none, associatedCardIds: [])

        self.init(cardInfo: cardInfo, role: role)
    }

    /// A scanned or primary card. The identity derives from the wallet config, the only source that is also
    /// correct for combined-seed cards (Twin).
    init(cardInfo: CardInfo, role: WalletCardsBackupCard.Role?) {
        let identity: WalletCardsBackupCard.Identity? = UserWalletId(cardInfo: cardInfo).map {
            .filled(userWalletId: $0.stringValue, isImported: cardInfo.card.hasImportedWallets)
        }

        self.init(
            cardId: cardInfo.card.cardId,
            cardPublicKey: cardInfo.card.cardPublicKey,
            role: role,
            identity: identity,
            curves: cardInfo.card.walletCurves,
            backupStatus: cardInfo.card.backupStatus.map(WalletCardsBackupCard.BackupStatus.init)
        )
    }
}
