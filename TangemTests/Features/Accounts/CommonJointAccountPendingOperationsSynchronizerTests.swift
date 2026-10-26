//
//  CommonJointAccountPendingOperationsSynchronizerTests.swift
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

@Suite("Tests for writing the unfinished joint account operations through the synchronizer")
struct CommonJointAccountPendingOperationsSynchronizerTests {
    @Test("A local update is written to the storage")
    func localUpdateIsWritten() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub()
        let sut = Self.makeSUT(storage: storage)

        try await sut.apply(.operation(Self.operation, cryptoAccountId: Self.accountId))

        #expect(storage.records == [Self.record])
        #expect(sut.pendingOperations == [Self.record])
    }

    @Test("An operation that has finished stays, stamped with the time it was learnt of")
    func finishedOperationStaysStamped() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(records: [Self.record])
        let sut = Self.makeSUT(storage: storage, dateProvider: FixedDateProvider(now: Self.now))

        try await sut.apply(.operation(JointAccountCompositionFixture.coinTransfer(status: .cancelled), cryptoAccountId: Self.accountId))

        #expect(storage.records == [Self.record(JointAccountCompositionFixture.coinTransfer(status: .cancelled, finishedAt: Self.now))])
    }

    @Test("A finished operation older than a day is dropped at the next write")
    func finishedOperationOlderThanADayIsDropped() async throws {
        let dayOld = JointAccountCompositionFixture.coinTransfer(status: .executed, finishedAt: Self.now.addingTimeInterval(-24 * 60 * 60))
        let storage = JointAccountsPendingOperationsPersistentStorageStub(records: [Self.record(dayOld)])
        let sut = Self.makeSUT(storage: storage, dateProvider: FixedDateProvider(now: Self.now))
        let checkpoint = await sut.checkpoint

        try await sut.apply(listing: [], requestedAt: checkpoint)

        #expect(storage.records.isEmpty)
    }

    @Test("A listing replaces what is stored")
    func listingReplacesTheStorage() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(records: [Self.record])
        let sut = Self.makeSUT(storage: storage)
        let checkpoint = await sut.checkpoint

        try await sut.apply(listing: [], requestedAt: checkpoint)

        #expect(storage.records.isEmpty)
    }

    @Test("A listing requested before an operation was written locally keeps that operation")
    func listingRequestedBeforeALocalWriteKeepsIt() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub()
        let sut = Self.makeSUT(storage: storage)
        let checkpoint = await sut.checkpoint

        try await sut.apply(.operation(Self.operation, cryptoAccountId: Self.accountId))
        try await sut.apply(listing: [], requestedAt: checkpoint)

        #expect(storage.records == [Self.record])
    }

    @Test("A listing requested before an operation was removed locally does not bring it back")
    func listingRequestedBeforeALocalRemovalDoesNotRestoreIt() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(records: [Self.record])
        let sut = Self.makeSUT(storage: storage)
        let checkpoint = await sut.checkpoint

        try await sut.apply(.operationRemoved(id: Self.operation.id, cryptoAccountId: Self.accountId))
        try await sut.apply(listing: [Self.record], requestedAt: checkpoint)

        #expect(storage.records.isEmpty)
    }

    @Test("A listing requested after an operation was written locally is taken as it is")
    func listingRequestedAfterALocalWriteWins() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub()
        let sut = Self.makeSUT(storage: storage)

        try await sut.apply(.operation(Self.operation, cryptoAccountId: Self.accountId))
        let checkpoint = await sut.checkpoint
        try await sut.apply(listing: [], requestedAt: checkpoint)

        #expect(storage.records.isEmpty)
    }

    @Test("What is stored is emitted right away, and every write follows")
    func publisherFollowsTheStorage() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(records: [Self.record])
        let sut = Self.makeSUT(storage: storage)
        var iterator = await sut.pendingOperationsPublisher.values_.makeAsyncIterator()

        let emittedFirst = await iterator.next()
        try await sut.apply(.operationRemoved(id: Self.operation.id, cryptoAccountId: Self.accountId))
        let emittedNext = await iterator.next()

        #expect(emittedFirst == [Self.record])
        #expect(emittedNext == [])
        withExtendedLifetime(sut) {}
    }
}

// MARK: - Helpers

private extension CommonJointAccountPendingOperationsSynchronizerTests {
    static let accountId = JointAccountCompositionFixture.caseFlippedCryptoAccountId
    static let operation = JointAccountCompositionFixture.coinTransfer()
    static let record = StoredJointAccountPendingOperations(cryptoAccountId: accountId, operations: [operation])
    static let now = Date(timeIntervalSince1970: 1_767_225_600)

    static func record(_ operation: JointAccountOperation) -> StoredJointAccountPendingOperations {
        StoredJointAccountPendingOperations(cryptoAccountId: accountId, operations: [operation])
    }

    static func makeSUT(
        storage: JointAccountsPendingOperationsPersistentStorage,
        dateProvider: DateProvider = SystemDateProvider()
    ) -> CommonJointAccountPendingOperationsSynchronizer {
        CommonJointAccountPendingOperationsSynchronizer(
            persistentStorage: storage,
            merger: JointAccountPendingOperationsMerger(dateProvider: dateProvider)
        )
    }
}
