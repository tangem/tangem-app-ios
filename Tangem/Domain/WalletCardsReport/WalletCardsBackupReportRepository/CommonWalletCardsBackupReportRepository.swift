//
//  CommonWalletCardsBackupReportRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

final class CommonWalletCardsBackupReportRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonWalletCardsBackupReportRepository.lockQueue")
    private var report: WalletCardsBackupReport = .empty

    init() {
        lockQueue.async { [weak self] in
            self?.loadReport()
        }
    }
}

// MARK: - WalletCardsBackupReportRepository

extension CommonWalletCardsBackupReportRepository: WalletCardsBackupReportRepository {
    func store(card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError?) {
        lockQueue.async { [weak self] in
            guard let self else { return }

            // A primary reporting itself must not fall back to its own stored record — that may be a stale
            // wallet from a previous onboarding of the same physical card (the store isn't cleared on a
            // factory reset).
            let inheritedIdentity = card.cardId == primaryCardId ? nil : report.cards[primaryCardId]?.identity
            let identity = card.identity ?? inheritedIdentity

            let mutated = apply(card: card, identity: identity ?? .blank(primaryCardId: primaryCardId), error: error)
            let applied = applyIdentityIfPossible(identity: identity, primaryCardId: primaryCardId)

            (mutated || applied) ? saveChanges() : ()
        }
    }
}

// MARK: - Mutations

private extension CommonWalletCardsBackupReportRepository {
    /// Overwrites the stored card with `card`, keeping an already-known `role` and `backupStatus` that the
    /// snapshot leaves unknown. Returns whether the store was mutated (i.e. needs persisting).
    func apply(
        card: WalletCardsCurrentlyProcessedCard,
        identity: WalletCardsBackupCard.Identity,
        error: TangemSdkError?
    ) -> Bool {
        ensureNotOnMainQueue()

        let existing = report.cards[card.cardId]
        let incoming = WalletCardsBackupCard(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey,
            identity: identity,
            role: card.role ?? existing?.role,
            backupStatus: card.backupStatus ?? existing?.backupStatus,
            curves: card.curves,
            errorCode: error?.code,
            errorMessage: error?.message
        )

        let hasChanges = incoming != existing
        report.cards[card.cardId] = incoming
        return hasChanges
    }

    /// Fills the group's still-`.blank` cards. Returns whether anything was promoted.
    func applyIdentityIfPossible(identity: WalletCardsBackupCard.Identity?, primaryCardId: String) -> Bool {
        guard let identity, identity.isFilled else {
            return false
        }

        let siblings = report.cards.filter {
            $0.value.identity.isMatched(primaryCardId: primaryCardId)
        }

        guard !siblings.isEmpty else {
            return false
        }

        for (cardId, sibling) in siblings {
            var promoted = sibling
            promoted.identity = identity
            report.cards[cardId] = promoted
        }

        return true
    }
}

// MARK: - Persistence

private extension CommonWalletCardsBackupReportRepository {
    func loadReport() {
        ensureNotOnMainQueue()

        do {
            report = try storage.value(for: .walletCardsBackupReports) ?? .empty
            WalletCardsReporterLogger.info("Loaded \(report)")
        } catch {
            WalletCardsReporterLogger.error("Couldn't load wallet cards backup report from storage", error: error)
        }
    }

    func saveChanges() {
        ensureNotOnMainQueue()

        do {
            try storage.store(value: report, for: .walletCardsBackupReports)
            WalletCardsReporterLogger.info("Saved \(report)")
        } catch {
            WalletCardsReporterLogger.error("Couldn't save wallet cards backup report to storage", error: error)
        }
    }
}

private extension WalletCardsBackupCard.Identity {
    func isMatched(primaryCardId cardId: String) -> Bool {
        switch self {
        case .blank(let primaryCardId): primaryCardId == cardId
        case .filled: false
        }
    }
}
