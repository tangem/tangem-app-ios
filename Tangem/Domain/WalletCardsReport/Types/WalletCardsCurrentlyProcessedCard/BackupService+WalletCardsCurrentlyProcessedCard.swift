//
//  BackupService+WalletCardsCurrentlyProcessedCard.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension BackupService {
    /// The role a card plays in the current ceremony. `nil` for the ceremony's final card, whose completion
    /// handler runs after the SDK has already reset its state.
    func role(for card: Card) -> WalletCardsBackupCard.Role? {
        if card.cardId == primaryCard?.cardId {
            return .primary
        }

        if let index = backupCards.firstIndex(where: { $0.cardId == card.cardId }) {
            return .backup(index: index + 1)
        }

        return nil
    }

    /// Snapshot of the card currently being finalized — used to attribute a finalize failure. `backupStatus`
    /// reads `.noBackup` because the back end takes no card without a status, while the ceremony phase can't
    /// tell a linked card from an unlinked one: a primary that the failed step had already flipped to
    /// `cardLinked` therefore reads as not backed up until the card is read again.
    var finalizingProcessedCard: WalletCardsCurrentlyProcessedCard? {
        switch currentState {
        case .finalizingPrimaryCard:
            guard let primaryCard else {
                return nil
            }

            return WalletCardsCurrentlyProcessedCard(
                cardId: primaryCard.cardId,
                cardPublicKey: primaryCard.cardPublicKey,
                role: .primary,
                identity: nil,
                curves: primaryCard.walletCurves,
                backupStatus: .noBackup
            )
        case .finalizingBackupCard(let index):
            // `index` is 1-based (the card being finalized), so shift to a 0-based array index.
            guard let backupCard = backupCards[safe: index - 1] else {
                return nil
            }

            return WalletCardsCurrentlyProcessedCard(
                cardId: backupCard.cardId,
                cardPublicKey: backupCard.cardPublicKey,
                role: .backup(index: index),
                identity: nil,
                curves: [],
                backupStatus: .noBackup
            )
        case .preparing, .finished:
            return nil
        }
    }
}
