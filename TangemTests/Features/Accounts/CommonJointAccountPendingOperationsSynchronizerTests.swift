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

@Suite("Tests for writing the unfinished joint account operations through the synchronizer", .timeLimit(.minutes(1)))
struct CommonJointAccountPendingOperationsSynchronizerTests {
    @Test("A local update is written at the account's Safe and read back right away")
    func localUpdateIsWritten() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub()
        let sut = Self.makeSUT(storage: storage)

        try await sut.apply(.localOperation(Self.operation, cryptoAccountId: Self.accountId))

        #expect(storage.items == [Self.item(Self.operation)])
        #expect(sut.pendingOperations == [Self.record])
    }

    @Test("An operation that has finished is stamped with the time it was learnt of and leaves what is in flight")
    func finishedOperationIsStamped() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(Self.operation)])
        let sut = Self.makeSUT(storage: storage, dateProvider: FixedDateProvider(now: Self.now))
        let cancelled = JointAccountCompositionFixture.coinTransfer(status: .cancelled)

        try await sut.apply(.localOperation(cancelled, cryptoAccountId: Self.accountId))

        #expect(storage.items == [Self.item(JointAccountCompositionFixture.coinTransfer(status: .cancelled, finishedAt: Self.now))])
        #expect(sut.pendingOperations.isEmpty)
    }

    @Test("A finished operation is never dropped, however long ago it finished")
    func finishedOperationIsKept() async throws {
        let dayOld = JointAccountCompositionFixture.coinTransfer(status: .executed, finishedAt: Self.now.addingTimeInterval(-48 * 60 * 60))
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(dayOld)])
        let sut = Self.makeSUT(storage: storage, dateProvider: FixedDateProvider(now: Self.now))
        let checkpoint = await sut.checkpoint

        try await sut.apply(listing: [Self.record(dayOld)], requestedAt: checkpoint)

        #expect(storage.items == [Self.item(dayOld)])
        #expect(storage.receivedChanges.allSatisfy { $0.isEmpty })
    }

    @Test("A listing adds only the in-flight operations nothing is stored for")
    func listingAddsOnlyUnknownInFlightOperations() async throws {
        let stored = JointAccountCompositionFixture.coinTransfer(id: "stored")
        let listedStored = JointAccountCompositionFixture.coinTransfer(id: "stored", status: .pending)
        let unknown = JointAccountCompositionFixture.coinTransfer(id: "unknown")
        let finished = JointAccountCompositionFixture.coinTransfer(id: "finished", status: .executed)
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(stored)])
        let sut = Self.makeSUT(storage: storage)
        let checkpoint = await sut.checkpoint

        try await sut.apply(listing: [Self.record(listedStored, unknown, finished)], requestedAt: checkpoint)

        #expect(storage.items == [Self.item(stored), Self.item(unknown)])
    }

    @Test("A listing does not take a finished operation back to in flight")
    func listingDoesNotRollBackAFinishedOperation() async throws {
        let executed = JointAccountCompositionFixture.coinTransfer(status: .executed, finishedAt: Self.now)
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(executed)])
        let sut = Self.makeSUT(storage: storage)
        let checkpoint = await sut.checkpoint

        try await sut.apply(listing: [Self.record], requestedAt: checkpoint)

        #expect(storage.items == [Self.item(executed)])
        #expect(sut.pendingOperations.isEmpty)
    }

    @Test("A local in-flight answer does not overwrite an operation already finished")
    func localOperationDoesNotOverwriteAFinishedOne() async throws {
        let executed = JointAccountCompositionFixture.coinTransfer(status: .executed, finishedAt: Self.now)
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(executed)])
        let sut = Self.makeSUT(storage: storage)

        try await sut.apply(.localOperation(JointAccountCompositionFixture.coinTransfer(status: .pending), cryptoAccountId: Self.accountId))

        #expect(storage.items == [Self.item(executed)])
    }

    @Test("A read anew of an operation nothing is stored for is written only once it has finished")
    func readAnewOfAnUnknownOperationIsWrittenOnlyFinished() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub()
        let sut = Self.makeSUT(storage: storage, dateProvider: FixedDateProvider(now: Self.now))
        let checkpoint = await sut.checkpoint

        try await sut.apply(refreshedOperation: Self.operation, forCryptoAccountId: Self.accountId, requestedAt: checkpoint)
        let itemsAfterInFlightRead = storage.items
        try await sut.apply(
            refreshedOperation: JointAccountCompositionFixture.coinTransfer(status: .failed),
            forCryptoAccountId: Self.accountId,
            requestedAt: checkpoint
        )

        #expect(itemsAfterInFlightRead.isEmpty)
        #expect(storage.items == [Self.item(JointAccountCompositionFixture.coinTransfer(status: .failed, finishedAt: Self.now))])
    }

    @Test("An operation the listing no longer reports stays, and only a removal takes it away")
    func onlyARemovalDropsAnOperation() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(Self.operation)])
        let sut = Self.makeSUT(storage: storage)
        let checkpoint = await sut.checkpoint

        try await sut.apply(listing: [], requestedAt: checkpoint)
        let itemsAfterListing = storage.items
        try await sut.apply(.operationRemoved(id: Self.operation.id, cryptoAccountId: Self.accountId))

        #expect(itemsAfterListing == [Self.item(Self.operation)])
        #expect(storage.items.isEmpty)
        #expect(storage.receivedChanges.last?.removedOperationIds == [Self.operation.id])
    }

    @Test("An operation of an account whose Safe the wallet does not know is not written")
    func operationOfAnAccountWithoutASafeIsSkipped() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub()
        let sut = Self.makeSUT(storage: storage, resolver: JointAccountSafeAddressResolverStub())
        let checkpoint = await sut.checkpoint

        try await sut.apply(.localOperation(Self.operation, cryptoAccountId: Self.accountId))
        try await sut.apply(listing: [Self.record(JointAccountCompositionFixture.coinTransfer(id: "listed"))], requestedAt: checkpoint)

        #expect(storage.items.isEmpty)
    }

    @Test("An operation stored at a Safe the wallet does not trust is left as it is, even by a removal")
    func operationAtAnUntrustedSafeIsLeftAlone() async throws {
        let storedAtUntrustedSafe = JointOperationHistoryItem(
            operation: Self.operation,
            cryptoAccountId: Self.accountId,
            safeAddress: "0x2b5ad5c4795c026514f8317c7a215e218dccd6cf",
            createdAt: Self.operation.createdAt,
            threshold: Self.operation.threshold
        )
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [storedAtUntrustedSafe])
        let sut = Self.makeSUT(storage: storage)

        try await sut.apply(.operationRemoved(id: Self.operation.id, cryptoAccountId: Self.accountId))

        #expect(storage.items == [storedAtUntrustedSafe])
        #expect(sut.pendingOperations.isEmpty)
    }

    @Test("A Safe kept for another wallet's account is read as this wallet's account")
    func operationAtTheSafeIsReadForThisWallet() async throws {
        let storedForAnotherWallet = JointOperationHistoryItem(
            operation: Self.operation,
            cryptoAccountId: "another-wallet-account",
            safeAddress: Self.safeAddress.lowercased(),
            createdAt: Self.operation.createdAt,
            threshold: Self.operation.threshold
        )
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [storedForAnotherWallet])
        let sut = Self.makeSUT(storage: storage)
        var iterator = Self.values(of: sut.pendingOperationsPublisher).makeAsyncIterator()

        let emittedFirst = await iterator.next()

        #expect(emittedFirst == [Self.record])
        withExtendedLifetime(sut) {}
    }

    @Test("A listing requested before an operation was written locally keeps that operation")
    func listingRequestedBeforeALocalWriteKeepsIt() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub()
        let sut = Self.makeSUT(storage: storage)
        let checkpoint = await sut.checkpoint

        try await sut.apply(.localOperation(Self.operation, cryptoAccountId: Self.accountId))
        try await sut.apply(listing: [], requestedAt: checkpoint)

        #expect(storage.items == [Self.item(Self.operation)])
    }

    @Test("A listing requested before an operation was removed locally does not bring it back")
    func listingRequestedBeforeALocalRemovalDoesNotRestoreIt() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(Self.operation)])
        let sut = Self.makeSUT(storage: storage)
        let checkpoint = await sut.checkpoint

        try await sut.apply(.operationRemoved(id: Self.operation.id, cryptoAccountId: Self.accountId))
        try await sut.apply(listing: [Self.record], requestedAt: checkpoint)

        #expect(storage.items.isEmpty)
    }

    @Test("A listing requested after an operation was removed locally brings it back, since the endpoint still reports it")
    func listingRequestedAfterALocalRemovalWins() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(Self.operation)])
        let sut = Self.makeSUT(storage: storage)

        try await sut.apply(.operationRemoved(id: Self.operation.id, cryptoAccountId: Self.accountId))
        let checkpoint = await sut.checkpoint
        try await sut.apply(listing: [Self.record], requestedAt: checkpoint)

        #expect(storage.items == [Self.item(Self.operation)])
    }

    @Test("A listing requested before an operation was read anew does not take back what the read stored")
    func listingRequestedBeforeAReadAnewKeepsIt() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(Self.operation)])
        let sut = Self.makeSUT(storage: storage)
        let pending = JointAccountCompositionFixture.coinTransfer(status: .pending)
        let checkpoint = await sut.checkpoint

        try await sut.apply(refreshedOperation: pending, forCryptoAccountId: Self.accountId, requestedAt: checkpoint)
        try await sut.apply(listing: [Self.record], requestedAt: checkpoint)

        #expect(storage.items == [Self.item(pending)])
    }

    @Test("A read anew requested before an operation was written locally keeps that write")
    func readAnewRequestedBeforeALocalWriteKeepsIt() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(Self.operation)])
        let sut = Self.makeSUT(storage: storage)
        let signed = JointAccountCompositionFixture.coinTransfer(status: .pending)
        let checkpoint = await sut.checkpoint

        try await sut.apply(.localOperation(signed, cryptoAccountId: Self.accountId))
        try await sut.apply(refreshedOperation: Self.operation, forCryptoAccountId: Self.accountId, requestedAt: checkpoint)

        #expect(storage.items == [Self.item(signed)])
    }

    @Test("A read anew requested after an operation was written locally is taken as it is")
    func readAnewRequestedAfterALocalWriteWins() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(Self.operation)])
        let sut = Self.makeSUT(storage: storage)
        let signed = JointAccountCompositionFixture.coinTransfer(status: .pending)

        try await sut.apply(.localOperation(signed, cryptoAccountId: Self.accountId))
        let checkpoint = await sut.checkpoint
        try await sut.apply(refreshedOperation: Self.operation, forCryptoAccountId: Self.accountId, requestedAt: checkpoint)

        #expect(storage.items == [Self.item(Self.operation)])
    }

    @Test("What is in flight is emitted right away, and every change of the storage follows, whoever wrote it")
    func publisherFollowsTheStorage() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(Self.operation)])
        let sut = Self.makeSUT(storage: storage)
        let synced = JointAccountCompositionFixture.coinTransfer(id: "synced")
        var iterator = Self.values(of: sut.pendingOperationsPublisher).makeAsyncIterator()

        let emittedFirst = await iterator.next()
        try await sut.apply(.operationRemoved(id: Self.operation.id, cryptoAccountId: Self.accountId))
        let emittedAfterRemoval = await iterator.next()
        storage.save([Self.item(synced)])
        let emittedAfterSync = await iterator.next()

        #expect(emittedFirst == [Self.record])
        #expect(emittedAfterRemoval == [])
        #expect(emittedAfterSync == [Self.record(synced)])
        withExtendedLifetime(sut) {}
    }

    @Test("An account the wallet learns the Safe of brings what is in flight at that Safe")
    func publisherFollowsTheAccountSafes() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(Self.operation)])
        let resolver = JointAccountSafeAddressResolverStub()
        let sut = Self.makeSUT(storage: storage, resolver: resolver)
        var iterator = Self.values(of: sut.pendingOperationsPublisher).makeAsyncIterator()

        let emittedFirst = await iterator.next()
        resolver.store(accountSafes: [Self.accountSafe])
        let emittedNext = await iterator.next()

        #expect(emittedFirst == [])
        #expect(emittedNext == [Self.record])
        withExtendedLifetime(sut) {}
    }

    @Test("An operation is followed by its identifier after it has finished")
    func operationIsFollowedAfterItFinished() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(items: [Self.item(Self.operation)])
        let sut = Self.makeSUT(storage: storage, dateProvider: FixedDateProvider(now: Self.now))
        let executed = JointAccountCompositionFixture.coinTransfer(status: .executed)
        var iterator = Self.values(of: sut.operationPublisher(id: Self.operation.id)).makeAsyncIterator()

        let emittedFirst = await iterator.next()
        try await sut.apply(.localOperation(executed, cryptoAccountId: Self.accountId))
        let emittedNext = await iterator.next()

        #expect(emittedFirst == Self.operation)
        #expect(emittedNext == JointAccountCompositionFixture.coinTransfer(status: .executed, finishedAt: Self.now))
        withExtendedLifetime(sut) {}
    }
}

// MARK: - Helpers

private extension CommonJointAccountPendingOperationsSynchronizerTests {
    static let accountId = JointAccountCompositionFixture.caseFlippedCryptoAccountId
    static let safeAddress = JointAccountCompositionFixture.Signed.checksummedSafeAddress
    static let accountSafe = JointAccountSafe(cryptoAccountId: accountId, safeAddress: safeAddress)
    static let operation = JointAccountCompositionFixture.coinTransfer()
    static let record = JointAccountOperations(cryptoAccountId: accountId, operations: [operation])
    static let now = Date(timeIntervalSince1970: 1_767_225_600)

    static func record(_ operations: JointAccountOperation...) -> JointAccountOperations {
        JointAccountOperations(cryptoAccountId: accountId, operations: operations)
    }

    static func item(_ operation: JointAccountOperation) -> JointOperationHistoryItem {
        JointOperationHistoryItem(
            operation: operation,
            cryptoAccountId: accountId,
            safeAddress: safeAddress.lowercased(),
            createdAt: operation.createdAt,
            threshold: operation.threshold
        )
    }

    static func values<Output>(of publisher: AnyPublisher<Output, Never>) -> AsyncPublisher<Publishers.Buffer<AnyPublisher<Output, Never>>> {
        publisher
            .buffer(size: 16, prefetch: .keepFull, whenFull: .dropOldest)
            .values
    }

    static func makeSUT(
        storage: JointAccountsPendingOperationsPersistentStorage,
        resolver: JointAccountSafeAddressResolver = JointAccountSafeAddressResolverStub(accountSafes: [accountSafe]),
        dateProvider: DateProvider = SystemDateProvider()
    ) -> CommonJointAccountPendingOperationsSynchronizer {
        CommonJointAccountPendingOperationsSynchronizer(
            persistentStorage: storage,
            safeAddressResolver: resolver,
            merger: JointAccountPendingOperationsMerger(dateProvider: dateProvider)
        )
    }
}
