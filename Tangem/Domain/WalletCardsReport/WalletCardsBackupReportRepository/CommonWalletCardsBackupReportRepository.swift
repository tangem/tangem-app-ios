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
    private let storage: PersistentStorageProtocol
    private let secureStorage: WalletCardsBackupReportSecureStorage
    private let lockQueue = DispatchQueue(label: "com.tangem.CommonWalletCardsBackupReportRepository.lockQueue")
    private let report = CurrentValueSubject<WalletCardsBackupReport, Never>(.empty)
    private var isReportLoaded = false
    private var attemptedCardLinkedHashes: Set<String> = []

    init(
        secureStorage: WalletCardsBackupReportSecureStorage = SecureStorage(),
        storage: PersistentStorageProtocol = InjectedValues[\.persistentStorage]
    ) {
        self.storage = storage
        self.secureStorage = secureStorage
        lockQueue.async { [weak self] in
            self?.loadReportIfNeeded()
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
        lockQueue.sync { loadReportIfNeeded() ? report.value.pendingReports.first : nil }
    }

    func store(card: WalletCardsCurrentlyProcessedCard, primaryCardId: String, error: TangemSdkError?) {
        lockQueue.async { [weak self] in
            guard let self, loadReportIfNeeded() else { return }

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
                primaryCardId: primaryCardId,
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

    func storePreviouslySavedCardIfNeeded(_ card: WalletCardsCurrentlyProcessedCard) {
        lockQueue.async { [weak self] in
            guard let self, loadReportIfNeeded(),
                  card.backupStatus == .cardLinked,
                  case .filled(let userWalletId, let isImported)? = card.identity else {
                return
            }

            var currentReport = report.value
            let deliveryHash = cardLinkedDeliveryHash(userWalletId: userWalletId, cardId: card.cardId)
            guard !currentReport.deliveredCardLinkedHashes.contains(deliveryHash),
                  !attemptedCardLinkedHashes.contains(deliveryHash),
                  !currentReport.pendingReports.contains(where: {
                      $0.userWalletId == userWalletId && $0.cards.contains {
                          $0.cardId == card.cardId && $0.backupStatus == .cardLinked && $0.role != nil
                      }
                  }) else {
                return
            }

            attemptedCardLinkedHashes.insert(deliveryHash)
            let existing = currentReport.cards[card.cardId].flatMap { $0.identity == card.identity ? $0 : nil }
            let observedCard = WalletCardsBackupCard(
                cardId: card.cardId,
                cardPublicKey: card.cardPublicKey,
                identity: .filled(userWalletId: userWalletId, isImported: isImported),
                role: card.role ?? existing?.role,
                backupStatus: card.backupStatus,
                curves: card.curves,
                errorCode: existing?.errorCode,
                errorMessage: existing?.errorMessage
            )
            if currentReport.cards[card.cardId]?.identity.isFilled != true || existing != nil {
                currentReport.cards[card.cardId] = observedCard
            }
            let pendingReport = currentReport.pendingReport(userWalletId: userWalletId, isImported: isImported, including: observedCard)
            enqueue(pendingReport, in: &currentReport)
            report.send(currentReport)
            saveChanges()
        }
    }

    func removePendingReport(_ pendingReport: WalletCardsWaitingDeliveryBackupCards, wasDelivered: Bool) {
        lockQueue.async { [weak self] in
            guard let self, loadReportIfNeeded() else { return }

            var updated = report.value
            updated.pendingReports.removeAll { $0.id == pendingReport.id }

            if wasDelivered {
                for card in pendingReport.cards where card.backupStatus == .cardLinked && card.role != nil {
                    updated.deliveredCardLinkedHashes.insert(cardLinkedDeliveryHash(userWalletId: pendingReport.userWalletId, cardId: card.cardId))
                }
            }

            guard updated.pendingReports.count != report.value.pendingReports.count ||
                updated.deliveredCardLinkedHashes != report.value.deliveredCardLinkedHashes else {
                return
            }

            report.send(updated)
            saveChanges()
        }
    }
}

// MARK: - Queue

private extension CommonWalletCardsBackupReportRepository {
    func cardLinkedDeliveryHash(userWalletId: String, cardId: String) -> String {
        UserWalletId(value: Data(hexString: userWalletId))
            .hashedStringValue(message: "wallet-cards-backup-delivery.\(cardId)")
    }

    func enqueue(_ pendingReport: WalletCardsWaitingDeliveryBackupCards, in report: inout WalletCardsBackupReport) {
        let queue = report.pendingReports + [pendingReport]
        report.pendingReports = Array(queue.suffix(Constants.maxPendingReports))
    }
}

// MARK: - Mutations

private extension CommonWalletCardsBackupReportRepository {
    /// Overwrites the stored card with `card`: only a known `role` of the same wallet survives, the rest mirrors
    /// the card even where it revealed nothing. Returns whether the store was mutated (i.e. needs persisting).
    func apply(
        card: WalletCardsCurrentlyProcessedCard,
        identity: WalletCardsBackupCard.Identity,
        primaryCardId: String,
        error: TangemSdkError?,
        to report: inout WalletCardsBackupReport
    ) -> Bool {
        let existing = report.cards[card.cardId]
        let role: WalletCardsBackupCard.Role? = if let knownRole = card.role {
            knownRole
        } else if let existing, existing.identity.isSameWallet(as: identity, primaryCardId: primaryCardId) {
            existing.role
        } else {
            nil
        }
        let incoming = WalletCardsBackupCard(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey,
            identity: identity,
            role: role,
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
    @discardableResult
    func loadReportIfNeeded() -> Bool {
        ensureNotOnMainQueue()
        guard !isReportLoaded else { return true }

        do {
            let stored: WalletCardsBackupReport
            if let data = try secureStorage.get(Constants.storageKey) {
                stored = try JSONDecoder().decode(WalletCardsBackupReport.self, from: data)
            } else {
                stored = .empty
            }
            removeLegacyReport()
            isReportLoaded = true
            report.send(stored)
            WalletCardsReporterLogger.info("Loaded \(stored)")
            return true
        } catch let error as DecodingError {
            WalletCardsReporterLogger.error("Couldn't decode the stored wallet cards backup report, starting over", error: error)
            removeLegacyReport()
            isReportLoaded = true
            return true
        } catch {
            WalletCardsReporterLogger.error("Couldn't load wallet cards backup report from storage", error: error)
            return false
        }
    }

    func saveChanges() {
        ensureNotOnMainQueue()

        do {
            try secureStorage.store(JSONEncoder().encode(report.value), forKey: Constants.storageKey, overwrite: true)
            removeLegacyReport()
            WalletCardsReporterLogger.info("Saved \(report.value)")
        } catch {
            WalletCardsReporterLogger.error("Couldn't save wallet cards backup report to storage", error: error)
        }
    }

    func removeLegacyReport() {
        do {
            try storage.remove(for: .walletCardsBackupReports)
        } catch {
            WalletCardsReporterLogger.error("Couldn't remove the legacy wallet cards backup report", error: error)
        }
    }
}

// MARK: - Constants

private extension CommonWalletCardsBackupReportRepository {
    enum Constants {
        static let maxPendingReports = 50
        static let storageKey = "wallet_cards_backup_reports"
    }
}

private extension WalletCardsBackupReport {
    func pendingReport(
        userWalletId: String,
        isImported: Bool,
        including observedCard: WalletCardsBackupCard? = nil
    ) -> WalletCardsWaitingDeliveryBackupCards {
        var snapshot = cards
        if let observedCard {
            snapshot[observedCard.cardId] = observedCard
        }
        let walletCards = snapshot.values
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

    func isSameWallet(as identity: Self, primaryCardId cardId: String) -> Bool {
        switch self {
        case .blank(let primaryCardId): primaryCardId == cardId
        case .filled(let userWalletId, _): userWalletId == identity.userWalletId
        }
    }
}
