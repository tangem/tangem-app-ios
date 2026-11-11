//
//  CommonJointAccountsPendingOperationsPersistentStorageTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
@testable import Tangem

// MARK: - Tests

@Suite("Tests for keeping the unfinished joint account operations in the app database", .timeLimit(.minutes(1)))
struct CommonJointAccountsPendingOperationsPersistentStorageTests {
    @Test("Only the operations in flight at the given Safes are read, the ones the history sync wrote included")
    func inFlightOperationsAreReadAtTheSafes() async throws {
        let awaiting = Factory.coinItem(id: "awaiting", status: .awaitingSignatures)
        let pending = Factory.coinItem(id: "pending", status: .pending)
        let finished = Factory.coinItem(id: "finished", status: .executed)
        let elsewhere = Self.item(Factory.coinItem(id: "elsewhere", status: .awaitingSignatures), safeAddress: Self.otherSafeAddress)

        let (read, readWithoutSafes) = try await withInjectedInMemoryAppDatabase {
            try await Self.saveFromHistorySync([awaiting, pending, finished, elsewhere])
            let sut = CommonJointAccountsPendingOperationsPersistentStorage()

            return (try sut.inFlightOperations(safeAddresses: [Factory.safeAddress]), try sut.inFlightOperations(safeAddresses: []))
        }

        #expect(Set(read) == [awaiting, pending])
        #expect(readWithoutSafes.isEmpty)
    }

    @Test("An operation in flight on a network the history does not index is read all the same")
    func inFlightOperationWithoutIndexIsRead() async throws {
        let unindexed = Factory.coinItem(id: "unindexed", status: .awaitingSignatures, chainId: Factory.unsupportedChainId)

        let read = try await withInjectedInMemoryAppDatabase {
            try await Self.saveFromHistorySync([unindexed])
            let sut = CommonJointAccountsPendingOperationsPersistentStorage()

            return try sut.inFlightOperations(safeAddresses: [Factory.safeAddress])
        }

        #expect(read == [unindexed])
    }

    @Test("An operation is read by its identifier also once it has finished")
    func finishedOperationIsReadById() async throws {
        let finished = Factory.coinItem(id: "finished", status: .executed)

        let (read, missing) = try await withInjectedInMemoryAppDatabase {
            try await Self.saveFromHistorySync([finished])
            let sut = CommonJointAccountsPendingOperationsPersistentStorage()

            return (try sut.operation(id: "finished"), try sut.operation(id: "missing"))
        }

        #expect(read == finished)
        #expect(missing == nil)
    }

    @Test("A write is handed the operations it names, finished ones included, and the ones in flight at the Safes")
    func writeIsHandedNamedAndInFlightOperations() async throws {
        let inFlight = Factory.coinItem(id: "in-flight", status: .awaitingSignatures)
        let named = Factory.coinItem(id: "named", status: .executed)
        let unnamed = Factory.coinItem(id: "unnamed", status: .executed)

        let handed = try await withInjectedInMemoryAppDatabase {
            try await Self.saveFromHistorySync([inFlight, named, unnamed])
            let sut = CommonJointAccountsPendingOperationsPersistentStorage()
            var handed: [JointOperationHistoryItem] = []

            try sut.update(operationIds: ["named", "missing"], safeAddresses: [Factory.safeAddress]) { stored in
                handed = stored
                return Self.changes()
            }

            return handed
        }

        #expect(Set(handed) == [inFlight, named])
    }

    @Test("An operation written here is read back in flight at its Safe")
    func writtenOperationIsReadBack() async throws {
        let local = Factory.coinItem(id: "local", status: .awaitingSignatures)

        let read = try await withInjectedInMemoryAppDatabase {
            let sut = CommonJointAccountsPendingOperationsPersistentStorage()
            try sut.update(operationIds: ["local"], safeAddresses: [Factory.safeAddress]) { _ in Self.changes(saved: [local]) }

            return try sut.inFlightOperations(safeAddresses: [Factory.safeAddress])
        }

        #expect(read == [local])
    }

    @Test("The last write wins over whatever is stored, a finished operation included", arguments: [JointAccountOperationStatus.executed, .failed, .cancelled])
    func lastWriteWins(finishedStatus: JointAccountOperationStatus) async throws {
        let finished = Factory.coinItem(id: "joint", status: finishedStatus)
        let inFlight = Factory.coinItem(id: "joint", status: .awaitingSignatures)

        let read = try await withInjectedInMemoryAppDatabase {
            try await Self.saveFromHistorySync([finished])
            let sut = CommonJointAccountsPendingOperationsPersistentStorage()
            try sut.update(operationIds: ["joint"], safeAddresses: [Factory.safeAddress]) { _ in
                Self.changes(saved: [inFlight])
            }

            return try sut.operation(id: "joint")
        }

        #expect(read == inFlight)
    }

    @Test("An answer of a stage this version does not know replaces the in-flight one and leaves what is in flight")
    func unknownStageLeavesTheInFlightSet() async throws {
        let unknown = Factory.coinItem(id: "joint", status: .unknown)

        let (read, inFlight) = try await withInjectedInMemoryAppDatabase {
            try await Self.saveFromHistorySync([Factory.coinItem(id: "joint", status: .awaitingSignatures)])
            let sut = CommonJointAccountsPendingOperationsPersistentStorage()
            try sut.update(operationIds: ["joint"], safeAddresses: [Factory.safeAddress]) { _ in
                Self.changes(saved: [unknown])
            }

            return (try sut.operation(id: "joint"), try sut.inFlightOperations(safeAddresses: [Factory.safeAddress]))
        }

        #expect(read == unknown)
        #expect(inFlight.isEmpty)
    }

    @Test("A removed operation leaves the database with its index rows, so saving it again for a token keeps it out of the coin's history")
    func removedOperationTakesItsIndexAlong() async throws {
        let kept = Factory.coinItem(id: "kept")

        let (removed, records) = try await withInjectedInMemoryAppDatabase {
            try await Self.saveFromHistorySync([Factory.coinItem(id: "reused", status: .awaitingSignatures), kept])
            let sut = CommonJointAccountsPendingOperationsPersistentStorage()
            try sut.update(operationIds: ["reused"], safeAddresses: [Factory.safeAddress]) { _ in Self.changes(removed: ["reused"]) }
            let removed = try sut.operation(id: "reused")
            try await Self.saveFromHistorySync([Factory.tokenItem(id: "reused")])

            return (removed, await Self.firstNonEmptyCoinRecords())
        }

        let expectedInfo = try Factory.info(kept)
        #expect(removed == nil)
        #expect(records == [.jointOperation(expectedInfo)])
    }

    @Test("Every write to the stored operations is announced, the history sync's included")
    func everyWriteIsAnnounced() async throws {
        let (announcedAfterSync, announcedAfterRemoval) = try await withInjectedInMemoryAppDatabase {
            let sut = CommonJointAccountsPendingOperationsPersistentStorage()
            var iterator = sut.didUpdatePublisher
                .buffer(size: 4, prefetch: .keepFull, whenFull: .dropOldest)
                .values
                .makeAsyncIterator()

            try await Self.saveFromHistorySync([Factory.coinItem(id: "synced", status: .pending)])
            let announcedAfterSync: Void? = await iterator.next()
            try sut.update(operationIds: ["synced"], safeAddresses: [Factory.safeAddress]) { _ in Self.changes(removed: ["synced"]) }
            let announcedAfterRemoval: Void? = await iterator.next()

            return (announcedAfterSync != nil, announcedAfterRemoval != nil)
        }

        #expect(announcedAfterSync)
        #expect(announcedAfterRemoval)
    }
}

// MARK: - Helpers

private extension CommonJointAccountsPendingOperationsPersistentStorageTests {
    typealias Factory = JointOperationHistoryTestDataFactory

    static let otherSafeAddress = "0x2b5ad5c4795c026514f8317c7a215e218dccd6cf"

    static func item(_ item: JointOperationHistoryItem, safeAddress: String) -> JointOperationHistoryItem {
        JointOperationHistoryItem(
            operation: item.operation,
            cryptoAccountId: item.cryptoAccountId,
            safeAddress: safeAddress,
            createdAt: item.createdAt,
            threshold: item.threshold
        )
    }

    static func changes(
        saved savedItems: [JointOperationHistoryItem] = [],
        removed removedOperationIds: [String] = []
    ) -> JointAccountsPendingOperationsChanges {
        JointAccountsPendingOperationsChanges(savedItems: savedItems, removedOperationIds: removedOperationIds)
    }

    static func saveFromHistorySync(_ items: [JointOperationHistoryItem]) async throws {
        try await CommonJointOperationsHistoryWriter(writer: CommonTransactionHistoryRecordsWriter()).save(remote: items)
    }

    static func firstNonEmptyCoinRecords() async -> [TransactionHistoryRecordsReader.Record] {
        let reader = CommonTransactionHistoryRecordsReader()
        defer { withExtendedLifetime(reader) {} }

        let updates = reader.updates(
            for: WalletModelId(tokenItem: .blockchain(.init(.base(testnet: false), derivationPath: nil))),
            walletModelAddressesPublisher: CurrentValueSubject<[String], Never>([Factory.safeAddress])
        )

        for await records in updates where records.isNotEmpty {
            return records
        }

        return []
    }
}
