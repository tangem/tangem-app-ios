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
    var pendingReportsPublisher: AnyPublisher<[WalletCardsWaitingDeliveryBackupCards], Never> {
        report
            .map(\.pendingReports)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var oldestPendingReport: WalletCardsWaitingDeliveryBackupCards? {
        lockQueue.sync { report.value.pendingReports.first }
    }

    func store(card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError?) {
        lockQueue.async { [weak self] in
            guard let self else { return }

            var currentReport = report.value

            // A primary reporting itself must not fall back to its own stored record — that may be a stale
            // wallet from a previous onboarding of the same physical card (the store isn't cleared on a
            // factory reset). A failed step is the exception: its snapshot carries no identity.
            let isPrimaryCard = card.cardId == primaryCardId
            let canInheritIdentity = !isPrimaryCard || error != nil
            let inheritedIdentity = canInheritIdentity ? currentReport.cards[primaryCardId]?.identity : nil
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

            if case .filled(let userWalletId, let isImported)? = identity {
                let pendingReport = currentReport.pendingReport(userWalletId: userWalletId, isImported: isImported)
                enqueue(pendingReport, in: &currentReport)
            }

            report.send(currentReport)
            saveChanges()
        }
    }

    func removePendingReport(_ pendingReport: WalletCardsWaitingDeliveryBackupCards) {
        lockQueue.async { [weak self] in
            guard let self else { return }

            var updated = report.value
            updated.pendingReports.removeAll { $0.id == pendingReport.id }

            guard updated.pendingReports.count != report.value.pendingReports.count else {
                return
            }

            report.send(updated)
            saveChanges()
        }
    }
}

// MARK: - Queue

private extension CommonWalletCardsBackupReportRepository {
    func enqueue(_ pendingReport: WalletCardsWaitingDeliveryBackupCards, in report: inout WalletCardsBackupReport) {
        let queue = report.pendingReports + [pendingReport]
        report.pendingReports = Array(queue.suffix(Constants.maxPendingReports))
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
            errorMessage: error?.localizedDescription
        )

        // A report that changes nothing must queue nothing, otherwise every repeated scan would send the same
        // card again.
        guard incoming != existing else {
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

// MARK: - Constants

private extension CommonWalletCardsBackupReportRepository {
    enum Constants {
        static let maxPendingReports = 50
    }
}

private extension WalletCardsBackupReport {
    func pendingReport(userWalletId: String, isImported: Bool) -> WalletCardsWaitingDeliveryBackupCards {
        let walletCards = cards.values
            .filter { $0.identity.userWalletId == userWalletId }
            .sorted { $0.cardId < $1.cardId }

        return WalletCardsWaitingDeliveryBackupCards(
            id: UUID(),
            userWalletId: userWalletId,
            isImported: isImported,
            cards: walletCards
        )
    }
}

private extension WalletCardsBackupCard.Identity {
    var userWalletId: String? {
        switch self {
        case .blank: nil
        case .filled(let userWalletId, _): userWalletId
        }
    }

    func isMatched(primaryCardId cardId: String) -> Bool {
        switch self {
        case .blank(let primaryCardId): primaryCardId == cardId
        case .filled: false
        }
    }
}
