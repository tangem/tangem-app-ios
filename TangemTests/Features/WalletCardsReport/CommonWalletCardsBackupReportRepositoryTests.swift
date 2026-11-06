//
//  CommonWalletCardsBackupReportRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
import TangemFoundation
@testable import Tangem

@Suite("CommonWalletCardsBackupReportRepository", .timeLimit(.minutes(1)))
struct CommonWalletCardsBackupReportRepositoryTests {
    private let error = TangemSdkError.userCancelled

    @Test("Repeated sign-ins queue one report containing the wallet's known cards")
    func repeatedSignInsKeepOnePendingReport() async throws {
        try await withRepository { repository, storage in
            repository.store(card: makeCard(identity: Constants.identity), primaryCardId: Constants.primaryCardId, error: nil)
            let card = makeSavedCard(id: Constants.backupCardId)
            repository.storePreviouslySavedCardIfNeeded(card)
            repository.storePreviouslySavedCardIfNeeded(card)
            _ = repository.oldestPendingReport

            let report: WalletCardsBackupReport = try #require(try storage.storedReport())
            #expect(report.pendingReports.count == 2)
            #expect(report.pendingReports.last?.cards.map(\.cardId) == [Constants.primaryCardId, Constants.backupCardId])
            #expect(report.pendingReports.last?.cards.last?.role == nil)
        }
    }

    @Test("A delivered problem is not queued again after the repository is recreated")
    func deliveredProblemSurvivesRestart() async throws {
        try await withRepository { repository, storage in
            let card = makeSavedCard()
            repository.storePreviouslySavedCardIfNeeded(card)
            let pending = try #require(repository.oldestPendingReport)
            repository.removePendingReport(pending, wasDelivered: true)
            #expect(repository.oldestPendingReport == nil)

            let reloaded = CommonWalletCardsBackupReportRepository(secureStorage: storage)
            reloaded.storePreviouslySavedCardIfNeeded(card)
            #expect(reloaded.oldestPendingReport == nil)
        }
    }

    @Test("A queued problem survives a restart without a duplicate report")
    func pendingProblemSurvivesRestart() async throws {
        try await withRepository { repository, storage in
            let card = makeSavedCard()
            repository.storePreviouslySavedCardIfNeeded(card)
            let pending = try #require(repository.oldestPendingReport)

            let reloaded = CommonWalletCardsBackupReportRepository(secureStorage: storage)
            reloaded.storePreviouslySavedCardIfNeeded(card)
            #expect(reloaded.oldestPendingReport?.id == pending.id)
            let stored: WalletCardsBackupReport = try #require(try storage.storedReport())
            #expect(stored.pendingReports.count == 1)
        }
    }

    @Test("A refused report is queued again on the next launch, not in the same one")
    func refusedProblemIsReportedAgainAfterRestart() async throws {
        try await withRepository { repository, storage in
            let card = makeSavedCard()
            repository.storePreviouslySavedCardIfNeeded(card)
            let pending = try #require(repository.oldestPendingReport)
            repository.removePendingReport(pending, wasDelivered: false)
            repository.storePreviouslySavedCardIfNeeded(card)
            #expect(repository.oldestPendingReport == nil)

            let reloaded = CommonWalletCardsBackupReportRepository(secureStorage: storage)
            reloaded.storePreviouslySavedCardIfNeeded(card)
            let retry = try #require(reloaded.oldestPendingReport)
            #expect(retry.id != pending.id)
        }
    }

    @Test("A successful in-flight report remains remembered after it leaves the pending queue")
    func lateDeliveryIsRemembered() async throws {
        try await withRepository { repository, storage in
            let card = makeSavedCard()
            repository.storePreviouslySavedCardIfNeeded(card)
            let pending = try #require(repository.oldestPendingReport)
            repository.removePendingReport(pending, wasDelivered: false)
            repository.removePendingReport(pending, wasDelivered: true)
            _ = repository.oldestPendingReport

            let reloaded = CommonWalletCardsBackupReportRepository(secureStorage: storage)
            reloaded.storePreviouslySavedCardIfNeeded(card)
            #expect(reloaded.oldestPendingReport == nil)
        }
    }

    @Test("Delivery during the ceremony suppresses the later sign-in report")
    func ceremonyDeliveryCoversSignIn() async throws {
        try await withRepository { repository, _ in
            let card = makeSavedCard(role: .primary)
            repository.store(card: card, primaryCardId: Constants.primaryCardId, error: error)
            let pending = try #require(repository.oldestPendingReport)
            repository.removePendingReport(pending, wasDelivered: true)
            repository.storePreviouslySavedCardIfNeeded(card)
            #expect(repository.oldestPendingReport == nil)
        }
    }

    @Test("Opening an old saved wallet preserves the card's newer wallet state")
    func savedWalletKeepsNewerCardIdentity() async throws {
        try await withRepository { repository, storage in
            let newerIdentity = WalletCardsBackupCard.Identity.filled(userWalletId: "wallet-new", isImported: false)
            repository.store(card: makeCard(identity: newerIdentity), primaryCardId: Constants.primaryCardId, error: nil)
            repository.storePreviouslySavedCardIfNeeded(makeSavedCard())
            _ = repository.oldestPendingReport
            let stored = try #require(try storage.storedReport())
            #expect(stored.cards[Constants.primaryCardId]?.identity == newerIdentity)
            #expect(stored.pendingReports.last?.userWalletId == Constants.userWalletId)
            #expect(stored.pendingReports.last?.cards.first?.backupStatus == .cardLinked)
            #expect(stored.pendingReports.last?.cards.first?.role == nil)
        }
    }

    @Test("The report file left by 6.6 is deleted, not carried over")
    func legacyReportIsDropped() async throws {
        let storage = SpyPersistentStorage()
        let legacy = WalletCardsBackupReport(cards: [:], pendingReports: [
            WalletCardsWaitingDeliveryBackupCards(id: UUID(), userWalletId: Constants.userWalletId, isImported: false, cards: []),
        ])
        try storage.store(value: legacy, for: .walletCardsBackupReports)
        try await withRepository(storage: storage) { repository, storage in
            #expect(repository.oldestPendingReport == nil)
            #expect(try storage.storedReport() == nil)
            let file: WalletCardsBackupReport? = try storage.value(for: .walletCardsBackupReports)
            #expect(file == nil)
        }
    }

    @Test("Loading a Keychain report retries interrupted legacy cleanup")
    func retriesLegacyCleanup() async throws {
        let storage = SpyPersistentStorage()
        try storage.store(value: WalletCardsBackupReport.empty, for: .walletCardsBackupReports)
        try storage.store(JSONEncoder().encode(WalletCardsBackupReport.empty), forKey: "wallet_cards_backup_reports", overwrite: true)
        try await withRepository(storage: storage) { repository, storage in
            #expect(repository.oldestPendingReport == nil)
            let file: WalletCardsBackupReport? = try storage.value(for: .walletCardsBackupReports)
            #expect(file == nil)
        }
    }

    @Test("A temporary Keychain read failure cannot replace the stored queue")
    func failedSecureReadPreservesQueue() async throws {
        try await withRepository { repository, storage in
            repository.storePreviouslySavedCardIfNeeded(makeSavedCard())
            let pending = try #require(repository.oldestPendingReport)
            storage.refusesSecureReads = true
            let reloaded = CommonWalletCardsBackupReportRepository(secureStorage: storage)
            reloaded.storePreviouslySavedCardIfNeeded(makeSavedCard(id: Constants.backupCardId))
            #expect(reloaded.oldestPendingReport == nil)
            storage.refusesSecureReads = false
            #expect(reloaded.oldestPendingReport?.id == pending.id)
            #expect(try storage.storedReport()?.pendingReports.count == 1)
        }
    }

    @Test("A failed primary step is reported under the wallet the card already belongs to")
    func failedPrimaryStepKeepsWallet() async throws {
        let pending = try await pendingCards { repository in
            repository.store(card: makeCard(identity: Constants.identity), primaryCardId: Constants.primaryCardId, error: nil)
            repository.store(card: makeCard(identity: nil), primaryCardId: Constants.primaryCardId, error: error)
        }

        #expect(pending.map(\.userWalletId) == [Constants.userWalletId, Constants.userWalletId])
        #expect(pending.last?.cards.map(\.cardId) == [Constants.primaryCardId])
        #expect(pending.last?.cards.first?.errorCode == error.code)
    }

    @Test("A successful primary step without a wallet doesn't pick up the wallet stored for the card")
    func successfulPrimaryStepWithoutWalletStaysUnreported() async throws {
        let pending = try await pendingCards { repository in
            repository.store(card: makeCard(identity: Constants.identity), primaryCardId: Constants.primaryCardId, error: nil)
            repository.store(card: makeCard(identity: nil), primaryCardId: Constants.primaryCardId, error: nil)
        }

        #expect(pending.count == 1)
    }

    @Test("A failure is reported with the error's description")
    func failureCarriesErrorDescription() async throws {
        let pending = try await pendingCards { repository in
            repository.store(card: makeCard(identity: Constants.identity), primaryCardId: Constants.primaryCardId, error: nil)
            repository.store(
                card: makeCard(id: Constants.backupCardId, role: .backup(index: 1), identity: nil),
                primaryCardId: Constants.primaryCardId,
                error: error
            )
        }

        let backupCard = pending.last?.cards.first { $0.cardId == Constants.backupCardId }

        #expect(backupCard?.errorCode == error.code)
        #expect(backupCard?.errorMessage == error.localizedDescription)
    }

    @Test("An unknown role doesn't carry over when a card moves to another wallet")
    func newWalletDoesNotInheritRole() async throws {
        let newIdentity = WalletCardsBackupCard.Identity.filled(userWalletId: "wallet-b", isImported: false)
        let pending = try await pendingCards { repository in
            repository.store(card: makeCard(identity: Constants.identity), primaryCardId: Constants.primaryCardId, error: nil)
            repository.store(card: makeCard(role: nil, identity: newIdentity), primaryCardId: Constants.primaryCardId, error: nil)
        }

        let report = try #require(pending.last)
        let card = try #require(report.cards.first)
        #expect(report.userWalletId == "wallet-b")
        #expect(card.role == nil)
    }

    @Test("An unknown role preserves the known role within the same wallet")
    func sameWalletKeepsRole() async throws {
        let pending = try await pendingCards { repository in
            repository.store(card: makeCard(identity: Constants.identity), primaryCardId: Constants.primaryCardId, error: error)
            repository.store(card: makeCard(role: nil, identity: Constants.identity), primaryCardId: Constants.primaryCardId, error: nil)
        }

        let report = try #require(pending.last)
        let card = try #require(report.cards.first)
        #expect(card.role == .primary)
    }
}

// MARK: - Helpers

private extension CommonWalletCardsBackupReportRepositoryTests {
    func withRepository(
        storage: SpyPersistentStorage = SpyPersistentStorage(),
        _ operation: (CommonWalletCardsBackupReportRepository, SpyPersistentStorage) throws -> Void
    ) async throws {
        try await InjectedDependenciesIsolation.shared.run {
            let previous = InjectedValues[\.persistentStorage]
            InjectedValues[\.persistentStorage] = storage
            defer { InjectedValues[\.persistentStorage] = previous }
            let repository = CommonWalletCardsBackupReportRepository(secureStorage: storage)
            defer { _ = repository.oldestPendingReport }
            try operation(repository, storage)
        }
    }

    func pendingCards(
        _ steps: (CommonWalletCardsBackupReportRepository) -> Void
    ) async throws -> [WalletCardsWaitingDeliveryBackupCards] {
        try await InjectedDependenciesIsolation.shared.run {
            let storage = SpyPersistentStorage()
            let previous = InjectedValues[\.persistentStorage]
            InjectedValues[\.persistentStorage] = storage
            defer { InjectedValues[\.persistentStorage] = previous }

            let repository = CommonWalletCardsBackupReportRepository(secureStorage: storage)
            steps(repository)
            await storage.waitForSaves(count: 2)
            _ = repository.oldestPendingReport

            return try await repository.pendingReportsPublisher.async()
        }
    }

    func makeCard(
        id: String = Constants.primaryCardId,
        role: WalletCardsBackupCard.Role? = .primary,
        identity: WalletCardsBackupCard.Identity?
    ) -> WalletCardsCurrentlyProcessedCard {
        WalletCardsCurrentlyProcessedCard(
            cardId: id,
            cardPublicKey: Data(repeating: 0x02, count: 33),
            role: role,
            identity: identity,
            curves: [.secp256k1],
            backupStatus: .noBackup
        )
    }

    func makeSavedCard(
        id: String = Constants.primaryCardId,
        role: WalletCardsBackupCard.Role? = nil
    ) -> WalletCardsCurrentlyProcessedCard {
        WalletCardsCurrentlyProcessedCard(
            cardId: id,
            cardPublicKey: Data(repeating: 0x02, count: 33),
            role: role,
            identity: Constants.identity,
            curves: [.secp256k1],
            backupStatus: .cardLinked
        )
    }

    enum Constants {
        static let primaryCardId = "AC01000000000001"
        static let backupCardId = "AC01000000000002"
        static let userWalletId = "wallet-a"
        static let identity = WalletCardsBackupCard.Identity.filled(userWalletId: userWalletId, isImported: false)
    }
}

// MARK: - Stubs

private final class SpyPersistentStorage: PersistentStorageProtocol, WalletCardsBackupReportSecureStorage {
    private let (saves, savesContinuation) = AsyncStream<Void>.makeStream()
    private let state = OSAllocatedUnfairLock(initialState: State())

    var refusesSecureReads: Bool {
        get { state.withLock { $0.refusesSecureReads } }
        set { state.withLock { $0.refusesSecureReads = newValue } }
    }

    func storedReport() throws -> WalletCardsBackupReport? {
        try state.withLock { try $0.secureData.map { try JSONDecoder().decode(WalletCardsBackupReport.self, from: $0) } }
    }

    func get(_ account: String) throws -> Data? {
        try state.withLock {
            if $0.refusesSecureReads { throw StorageError.unavailable }
            return $0.secureData
        }
    }

    func store(_ object: Data, forKey account: String, overwrite: Bool) throws {
        state.withLock { $0.secureData = object }
        savesContinuation.yield()
    }

    func value<T: Decodable>(for key: PersistentStorageKey) throws -> T? {
        try state.withLock { try $0.legacyData.map { try JSONDecoder().decode(T.self, from: $0) } }
    }

    func store<T: Encodable>(value: T, for key: PersistentStorageKey) throws {
        let encoded = try JSONEncoder().encode(value)
        state.withLock { $0.legacyData = encoded }
    }

    func remove(for key: PersistentStorageKey) throws {
        state.withLock { $0.legacyData = nil }
    }

    func waitForSaves(count: Int) async {
        for await _ in saves.prefix(count) {}
    }

    private struct State {
        var legacyData: Data?
        var secureData: Data?
        var refusesSecureReads = false
    }

    private enum StorageError: Error {
        case unavailable
    }
}
