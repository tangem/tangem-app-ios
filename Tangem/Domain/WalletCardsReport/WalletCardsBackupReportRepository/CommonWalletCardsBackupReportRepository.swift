//
//  CommonWalletCardsBackupReportRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation

final class CommonWalletCardsBackupReportRepository {
    @Injected(\.persistentStorage) private var storage: PersistentStorageProtocol

    private let lockQueue = DispatchQueue(label: "com.tangem.CommonWalletCardsBackupReportRepository.lockQueue")
    private let report = CurrentValueSubject<WalletCardsBackupReport, Never>(.empty)

    init() {
        lockQueue.async { [weak self] in
            self?.loadReport()
        }
    }
}

// MARK: - WalletCardsBackupReportRepository

extension CommonWalletCardsBackupReportRepository: WalletCardsBackupReportRepository {
    var pendingToDeliveryPublisher: AnyPublisher<[WalletCardsWaitingDeliveryBackupCards], Never> {
        report
            .map(\.waitingDelivery)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func store(card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError?) {
        lockQueue.async { [weak self] in
            guard let self else { return }

            var currentReport = report.value

            // A primary reporting itself must not fall back to its own stored record — that may be a stale
            // wallet from a previous onboarding of the same physical card (the store isn't cleared on a
            // factory reset).
            let isPrimaryCard = card.cardId == primaryCardId
            let inheritedIdentity = isPrimaryCard ? nil : currentReport.cards[primaryCardId]?.identity
            let identity = card.identity ?? inheritedIdentity

            let appliedCard = apply(
                card: card,
                identity: identity ?? .blank(primaryCardId: primaryCardId),
                error: error,
                to: &currentReport
            )

            let appliedIdentity = applyIdentityIfPossible(
                identity: identity,
                primaryCardId: primaryCardId,
                in: &currentReport
            )

            guard appliedCard || appliedIdentity else {
                return
            }

            report.send(currentReport)
            saveChanges()
        }
    }

    func markDelivered(report cards: WalletCardsWaitingDeliveryBackupCards) {
        lockQueue.async { [weak self] in
            guard let self else { return }

            var updated = report.value

            // Only cards that still hold exactly what was sent get marked: a report that landed while the
            // request was in flight put its card back to waiting on purpose.
            let delivered = cards.cards.filter { updated.cards[$0.cardId] == $0 }

            guard !delivered.isEmpty else {
                return
            }

            delivered.forEach { updated.cards[$0.cardId]?.deliveryState = .delivered }

            report.send(updated)
            saveChanges()
        }
    }
}

// MARK: - Mutations

private extension CommonWalletCardsBackupReportRepository {
    /// Overwrites the stored card with `card`: only a known `role` survives, the rest mirrors the card even
    /// where it revealed nothing. Returns whether the store was mutated (i.e. needs persisting).
    func apply(
        card: WalletCardsCurrentlyProcessedCard,
        identity: WalletCardsBackupCard.Identity,
        error: TangemSdkError?,
        to report: inout WalletCardsBackupReport
    ) -> Bool {
        let existing = report.cards[card.cardId]
        let incoming = WalletCardsBackupCard(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey,
            identity: identity,
            role: card.role ?? existing?.role,
            backupStatus: card.backupStatus,
            curves: card.curves,
            errorCode: error?.code,
            errorMessage: error?.message,
            deliveryState: .waitingForDelivery
        )

        // A report that changes nothing must keep the card's delivery state, otherwise every repeated scan
        // would send the same card again. A real change resets it to `.waitingForDelivery`, which queues it.
        guard incoming != existing?.withoutDeliveryMark else {
            return false
        }

        report.cards[card.cardId] = incoming
        return true
    }

    /// Fills the group's still-`.blank` cards. Returns whether anything was promoted.
    func applyIdentityIfPossible(
        identity: WalletCardsBackupCard.Identity?,
        primaryCardId: String,
        in report: inout WalletCardsBackupReport
    ) -> Bool {
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
            let stored: WalletCardsBackupReport = try storage.value(for: .walletCardsBackupReports) ?? .empty
            report.send(stored)
            WalletCardsReporterLogger.info("Loaded \(stored)")
        } catch {
            WalletCardsReporterLogger.error("Couldn't load wallet cards backup report from storage", error: error)
        }
    }

    func saveChanges() {
        ensureNotOnMainQueue()

        do {
            try storage.store(value: report.value, for: .walletCardsBackupReports)
            WalletCardsReporterLogger.info("Saved \(report.value)")
        } catch {
            WalletCardsReporterLogger.error("Couldn't save wallet cards backup report to storage", error: error)
        }
    }
}

private extension WalletCardsBackupReport {
    /// Sorted — both the groups and the cards inside them — so that an unchanged store always produces an
    /// equal value; dictionary iteration order alone would make `removeDuplicates()` useless.
    var waitingDelivery: [WalletCardsWaitingDeliveryBackupCards] {
        var walletCards: [String: (isImported: Bool, cards: [WalletCardsBackupCard])] = [:]

        for card in cards.values where card.deliveryState == .waitingForDelivery {
            guard case .filled(let userWalletId, let isImported) = card.identity else {
                continue
            }

            walletCards[userWalletId, default: (isImported, [])].cards.append(card)
        }

        return walletCards.map { userWalletId, group in
            WalletCardsWaitingDeliveryBackupCards(
                userWalletId: userWalletId,
                isImported: group.isImported,
                cards: group.cards.sorted { $0.cardId < $1.cardId }
            )
        }
        .sorted { $0.userWalletId < $1.userWalletId }
    }
}

private extension WalletCardsBackupCard {
    /// The card as it would look before any delivery, for comparing reported state alone.
    var withoutDeliveryMark: WalletCardsBackupCard {
        var card = self
        card.deliveryState = .waitingForDelivery
        return card
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
