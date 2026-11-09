//
//  CommonJointAccountPendingOperationsRepositoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import BigInt
import Testing
import TangemFoundation
@testable import Tangem

// MARK: - Tests

@Suite("Tests for keeping a wallet's unfinished joint account operations")
struct CommonJointAccountPendingOperationsRepositoryTests {
    @Test("The operation the endpoint registers is handed to the synchronizer under its account")
    func registeredOperationIsApplied() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub()
        let networkService = JointAccountsNetworkServiceStub(operationAnswer: Self.operation())
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        let operation = try await sut.createOperation(Self.request(), forCryptoAccountId: Self.accountId)

        #expect(operation == Self.operation())
        #expect(networkService.createdRequests == [Self.request()])
        #expect(synchronizer.appliedUpdates == [.localOperation(Self.operation(), cryptoAccountId: Self.accountId)])
    }

    @Test("A signed operation is sent with its transaction and signature, and the endpoint's answer is applied")
    func signedOperationIsApplied() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub()
        let networkService = JointAccountsNetworkServiceStub(operationAnswer: Self.operation(status: .pending))
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        try await sut.signOperation(
            id: Self.operationId,
            safeTransaction: Self.safeTransaction(),
            signature: Self.signature,
            forCryptoAccountId: Self.accountId
        )

        let signed = try #require(networkService.signedOperations.first)
        #expect(networkService.signedOperations.count == 1)
        #expect(signed.id == Self.operationId)
        #expect(signed.safeTransaction == Self.safeTransaction())
        #expect(signed.signature == Self.signature)
        #expect(synchronizer.appliedUpdates == [.localOperation(Self.operation(status: .pending), cryptoAccountId: Self.accountId)])
    }

    @Test("A rejected operation the endpoint still reports is applied as it now stands")
    func rejectedOperationStillReportedIsApplied() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub()
        let answer = Self.operation(signatures: [Self.signed, Self.declined])
        let networkService = JointAccountsNetworkServiceStub(operationAnswer: answer)
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        try await sut.rejectOperation(id: Self.operationId, forCryptoAccountId: Self.accountId)

        #expect(networkService.rejectedOperationIds == [Self.operationId])
        #expect(synchronizer.appliedUpdates == [.localOperation(answer, cryptoAccountId: Self.accountId)])
    }

    @Test("A rejected operation the endpoint deleted is removed")
    func rejectedOperationDeletedByTheEndpointIsRemoved() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub()
        let networkService = JointAccountsNetworkServiceStub(operationAnswer: nil)
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        try await sut.rejectOperation(id: Self.operationId, forCryptoAccountId: Self.accountId)

        #expect(networkService.rejectedOperationIds == [Self.operationId])
        #expect(synchronizer.appliedUpdates == [.operationRemoved(id: Self.operationId, cryptoAccountId: Self.accountId)])
    }

    @Test("Nothing is sent or applied while the feature is off")
    func nothingIsSentWhileTheFeatureIsOff() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub()
        let networkService = JointAccountsNetworkServiceStub(operationAnswer: Self.operation(status: .pending))
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer, isJointAccountsAvailable: false)

        await #expect(throws: CommonJointAccountPendingOperationsRepository.InternalError.featureUnavailable) {
            try await sut.createOperation(Self.request(), forCryptoAccountId: Self.accountId)
        }
        await #expect(throws: CommonJointAccountPendingOperationsRepository.InternalError.featureUnavailable) {
            try await sut.signOperation(
                id: Self.operationId,
                safeTransaction: Self.safeTransaction(),
                signature: Self.signature,
                forCryptoAccountId: Self.accountId
            )
        }
        await #expect(throws: CommonJointAccountPendingOperationsRepository.InternalError.featureUnavailable) {
            try await sut.rejectOperation(id: Self.operationId, forCryptoAccountId: Self.accountId)
        }
        await #expect(throws: CommonJointAccountPendingOperationsRepository.InternalError.featureUnavailable) {
            _ = try await sut.reloadPendingOperation(with: Self.operationId, in: Self.accountId, knownETag: nil)
        }

        #expect(networkService.operationCallsCount == 0)
        #expect(synchronizer.appliedUpdates.isEmpty)
    }

    @Test("No frequent updates are handed back for an operation that is no longer in flight")
    func noFrequentUpdatesForAnOperationNoLongerInFlight() {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub(pendingOperations: [Self.record(operations: [Self.operation(status: .executed)])])
        let sut = Self.makeSUT(networkService: JointAccountsNetworkServiceStub(), synchronizer: synchronizer)

        #expect(sut.requestFrequentUpdates(operationId: Self.operationId) == nil)
    }

    @Test("Frequent updates asked for an operation in flight read it anew under its account right away")
    func frequentUpdatesReadTheOperationRightAway() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub(pendingOperations: [Self.record(operations: [Self.operation()])])
        let networkService = JointAccountsNetworkServiceStub(fetchedOperationAnswers: [.success(.notModified)])
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        try await Self.readAnewOnce(through: sut, networkService: networkService)

        #expect(networkService.fetchedOperations.map(\.id) == [Self.operationId])
    }

    @Test("An operation keeps its poller, and the tag it learnt, for as long as it is in flight")
    func pollerIsKeptWhileTheOperationIsInFlight() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub(pendingOperations: [Self.record(operations: [Self.operation()])])
        let networkService = JointAccountsNetworkServiceStub(fetchedOperationAnswers: [
            .success(.modified(Self.historyItem(status: .pending), eTag: "v2")),
            .success(.notModified),
        ])
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        try await Self.readAnewOnce(through: sut, networkService: networkService)
        synchronizer.store(pendingOperations: [Self.record(operations: [Self.operation(status: .pending)])])
        try await Self.readAnewOnce(through: sut, networkService: networkService)

        #expect(networkService.fetchedOperations.map(\.knownETag) == [nil, "v2"])
    }

    @Test("A poller goes with its operation when the store drops it, and a new one comes with the operation's return")
    func pollerGoesWithItsOperation() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub(pendingOperations: [Self.record(operations: [Self.operation()])])
        let networkService = JointAccountsNetworkServiceStub(fetchedOperationAnswers: [
            .success(.modified(Self.historyItem(status: .awaitingSignatures), eTag: "v2")),
            .success(.notModified),
        ])
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        try await Self.readAnewOnce(through: sut, networkService: networkService)
        synchronizer.store(pendingOperations: [])
        synchronizer.store(pendingOperations: [Self.record(operations: [Self.operation()])])
        try await Self.readAnewOnce(through: sut, networkService: networkService)

        #expect(networkService.fetchedOperations.map(\.knownETag) == [nil, nil])
    }

    @Test("An operation is read anew with the poller's tag, applied under its account, and the answer is handed back")
    func operationReadAnewIsApplied() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub(pendingOperations: [Self.record(operations: [Self.operation()])])
        let item = Self.historyItem(status: .pending)
        let networkService = JointAccountsNetworkServiceStub(fetchedOperationAnswers: [.success(.modified(item, eTag: "v2"))])
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        let result = try await sut.reloadPendingOperation(with: Self.operationId, in: Self.accountId, knownETag: "v1")

        #expect(networkService.fetchedOperations.map(\.id) == [Self.operationId])
        #expect(networkService.fetchedOperations.map(\.knownETag) == ["v1"])
        #expect(synchronizer.appliedUpdates == [.operationRefreshed(item.operation, cryptoAccountId: Self.accountId)])
        #expect(result == .modified(item, eTag: "v2"))
    }

    @Test(
        "An operation the endpoint no longer knows, or no longer shows this wallet, is removed",
        arguments: [JointOperationError.operationNotFound, .notAMember]
    )
    func operationGoneFromTheEndpointIsRemoved(error: JointOperationError) async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub(pendingOperations: [Self.record(operations: [Self.operation()])])
        let networkService = JointAccountsNetworkServiceStub(fetchedOperationAnswers: [.failure(error)])
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        let result = try await sut.reloadPendingOperation(with: Self.operationId, in: Self.accountId, knownETag: nil)

        #expect(result == .notModified)
        #expect(synchronizer.appliedUpdates == [.operationRemoved(id: Self.operationId, cryptoAccountId: Self.accountId)])
    }

    @Test("A finished operation kept for the day is not read anew")
    func finishedOperationIsNotRead() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub(pendingOperations: [Self.record(operations: [Self.operation(status: .executed)])])
        let networkService = JointAccountsNetworkServiceStub(fetchedOperationAnswers: [.success(.notModified)])
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        _ = try await sut.reloadPendingOperation(with: Self.operationId, in: Self.accountId, knownETag: nil)

        #expect(networkService.fetchedOperations.isEmpty)
        #expect(synchronizer.appliedUpdates.isEmpty)
    }

    @Test("An operation no longer stored is not read")
    func operationNoLongerStoredIsNotRead() async throws {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub()
        let networkService = JointAccountsNetworkServiceStub(fetchedOperationAnswers: [.success(.notModified)])
        let sut = Self.makeSUT(networkService: networkService, synchronizer: synchronizer)

        _ = try await sut.reloadPendingOperation(with: Self.operationId, in: Self.accountId, knownETag: nil)

        #expect(networkService.fetchedOperations.isEmpty)
        #expect(synchronizer.appliedUpdates.isEmpty)
    }

    @Test("Nothing is polled while the feature is off")
    func nothingIsPolledWhileTheFeatureIsOff() {
        let synchronizer = JointAccountPendingOperationsSynchronizerStub(pendingOperations: [Self.record(operations: [Self.operation()])])
        let sut = Self.makeSUT(networkService: JointAccountsNetworkServiceStub(), synchronizer: synchronizer, isJointAccountsAvailable: false)

        #expect(sut.requestFrequentUpdates(operationId: Self.operationId) == nil)
    }
}

// MARK: - Helpers

private extension CommonJointAccountPendingOperationsRepositoryTests {
    static let accountId = "0F2A4B6C8D0E2F4A61C8A9E7D6053A1B4C7E2F8D9A0B3C5E7F1A2D4B6C8E0F2A"
    static let operationId = "0E2F4A6C-8D0B-4C5E-9F1A-2D4B6C8E0F2A"
    static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
    static let initiator = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf"
    static let coSigner = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
    static let signature = Data(repeating: 0x1b, count: 65)

    static let signed = JointAccountOperation.Signature(address: initiator, state: .signed, at: "2026-09-02T10:15:00Z")
    static let declined = JointAccountOperation.Signature(address: coSigner, state: .declined, at: "2026-09-02T10:20:00Z")

    static func makeSUT(
        networkService: JointAccountsNetworkService,
        synchronizer: JointAccountPendingOperationsSynchronizer,
        isJointAccountsAvailable: Bool = true
    ) -> CommonJointAccountPendingOperationsRepository {
        CommonJointAccountPendingOperationsRepository(
            networkService: networkService,
            synchronizer: synchronizer,
            isJointAccountsAvailable: isJointAccountsAvailable
        )
    }

    static func readAnewOnce(
        through sut: CommonJointAccountPendingOperationsRepository,
        networkService: JointAccountsNetworkServiceStub
    ) async throws {
        let fetchesCount = networkService.fetchedOperations.count
        let subscription = try #require(sut.requestFrequentUpdates(operationId: operationId))
        try await networkService.waitForFetches(reaching: fetchesCount + 1)
        subscription.cancel()
        try await Task.sleep(for: .milliseconds(50))
    }

    static func record(operations: [JointAccountOperation]) -> StoredJointAccountPendingOperations {
        StoredJointAccountPendingOperations(cryptoAccountId: accountId, operations: operations)
    }

    static func request() -> JointAccountOperationRequest {
        JointAccountOperationRequest(safeAddress: safeAddress, chainId: 1, safeTransaction: safeTransaction(), signature: signature)
    }

    static func safeTransaction() -> SafeTransaction {
        SafeTransaction(
            to: coSigner,
            value: BigUInt(10).power(18),
            data: Data(),
            operation: 0,
            safeTxGas: 23_520,
            baseGas: 100_000,
            gasPrice: 1_575_000_000,
            gasToken: "0x0000000000000000000000000000000000000000",
            refundReceiver: initiator,
            nonce: 7
        )
    }

    static func historyItem(status: JointAccountOperationStatus) -> JointOperationHistoryItem {
        JointOperationHistoryItem(
            operation: operation(status: status),
            cryptoAccountId: accountId,
            safeAddress: safeAddress,
            createdAt: Date(timeIntervalSince1970: 1_767_225_600),
            threshold: 2
        )
    }

    static func operation(
        id: String = operationId,
        status: JointAccountOperationStatus = .awaitingSignatures,
        signatures: [JointAccountOperation.Signature] = [signed]
    ) -> JointAccountOperation {
        JointAccountOperation(
            id: id,
            chainId: 1,
            safeTransaction: safeTransaction(),
            status: status,
            txHash: nil,
            finishedAt: nil,
            cancelReason: nil,
            initiator: initiator,
            signatures: signatures
        )
    }
}
