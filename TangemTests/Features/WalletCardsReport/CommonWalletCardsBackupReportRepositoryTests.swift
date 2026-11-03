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
    func pendingCards(
        _ steps: (CommonWalletCardsBackupReportRepository) -> Void
    ) async throws -> [WalletCardsWaitingDeliveryBackupCards] {
        try await InjectedDependenciesIsolation.shared.run {
            let storage = SpyPersistentStorage()
            let previous = InjectedValues[\.persistentStorage]
            InjectedValues[\.persistentStorage] = storage
            defer { InjectedValues[\.persistentStorage] = previous }

            let repository = CommonWalletCardsBackupReportRepository()
            steps(repository)
            await storage.waitForSaves(count: 2)

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

    enum Constants {
        static let primaryCardId = "AC01000000000001"
        static let backupCardId = "AC01000000000002"
        static let userWalletId = "wallet-a"
        static let identity = WalletCardsBackupCard.Identity.filled(userWalletId: userWalletId, isImported: false)
    }
}

// MARK: - Stubs

private final class SpyPersistentStorage: PersistentStorageProtocol {
    private let (saves, savesContinuation) = AsyncStream<Void>.makeStream()

    func value<T: Decodable>(for key: PersistentStorageKey) throws -> T? {
        nil
    }

    func store<T: Encodable>(value: T, for key: PersistentStorageKey) throws {
        guard value is WalletCardsBackupReport else {
            return
        }

        savesContinuation.yield()
    }

    func remove(for key: PersistentStorageKey) throws {}

    func waitForSaves(count: Int) async {
        for await _ in saves.prefix(count) {}
    }
}
