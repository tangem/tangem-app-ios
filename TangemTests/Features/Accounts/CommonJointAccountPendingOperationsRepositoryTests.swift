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
    @Test("The operation the endpoint registers is stored under its account")
    func registeredOperationIsStored() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub()
        let networkService = JointAccountsNetworkServiceStub(operationAnswer: Self.operation())
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

        let operation = try await sut.createOperation(Self.request(), forCryptoAccountId: Self.accountId)

        #expect(operation == Self.operation())
        #expect(networkService.createdRequests == [Self.request()])
        #expect(storage.records == [Self.record(operations: [Self.operation()])])
    }

    @Test("A signed operation is sent with its transaction and signature and stored as the endpoint now reports it")
    func signedOperationReplacesTheStoredOne() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(records: [Self.record(operations: [Self.operation()])])
        let networkService = JointAccountsNetworkServiceStub(operationAnswer: Self.operation(status: .pending))
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

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
        #expect(storage.records == [Self.record(operations: [Self.operation(status: .pending)])])
    }

    @Test("A rejected operation the endpoint still reports is stored as it now stands")
    func rejectedOperationStillReportedIsStored() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(records: [Self.record(operations: [Self.operation()])])
        let networkService = JointAccountsNetworkServiceStub(operationAnswer: Self.operation(signatures: [Self.signed, Self.declined]))
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

        try await sut.rejectOperation(id: Self.operationId, forCryptoAccountId: Self.accountId)

        #expect(networkService.rejectedOperationIds == [Self.operationId])
        #expect(storage.records == [Self.record(operations: [Self.operation(signatures: [Self.signed, Self.declined])])])
    }

    @Test("A rejected operation the endpoint deleted is dropped from the store")
    func rejectedOperationDeletedByTheEndpointIsDropped() async throws {
        let storage = JointAccountsPendingOperationsPersistentStorageStub(records: [Self.record(operations: [Self.operation()])])
        let networkService = JointAccountsNetworkServiceStub(operationAnswer: nil)
        let sut = Self.makeSUT(networkService: networkService, storage: storage)

        try await sut.rejectOperation(id: Self.operationId, forCryptoAccountId: Self.accountId)

        #expect(networkService.rejectedOperationIds == [Self.operationId])
        #expect(storage.records.flatMap(\.operations).isEmpty)
    }

    @Test("Nothing is sent to the endpoint while the feature is off, and what is stored stands")
    func nothingIsSentWhileTheFeatureIsOff() async throws {
        let stored = Self.record(operations: [Self.operation()])
        let storage = JointAccountsPendingOperationsPersistentStorageStub(records: [stored])
        let networkService = JointAccountsNetworkServiceStub(operationAnswer: Self.operation(status: .pending))
        let sut = Self.makeSUT(networkService: networkService, storage: storage, isJointAccountsAvailable: false)

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

        #expect(networkService.operationCallsCount == 0)
        #expect(storage.records == [stored])
    }

    @Test("What is stored is emitted right away, and what is written to the storage afterwards follows")
    func publisherFollowsTheStorage() async throws {
        let stored = Self.record(operations: [Self.operation()])
        let storage = JointAccountsPendingOperationsPersistentStorageStub(records: [stored])
        let sut = Self.makeSUT(networkService: JointAccountsNetworkServiceStub(), storage: storage)
        var iterator = await sut.pendingOperationsPublisher.values_.makeAsyncIterator()

        let emittedFirst = await iterator.next()
        try storage.replace(with: [])
        let emittedNext = await iterator.next()

        #expect(emittedFirst == [stored])
        #expect(emittedNext == [])
        withExtendedLifetime(sut) {}
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
        storage: JointAccountsPendingOperationsPersistentStorage,
        isJointAccountsAvailable: Bool = true
    ) -> CommonJointAccountPendingOperationsRepository {
        CommonJointAccountPendingOperationsRepository(
            networkService: networkService,
            persistentStorage: storage,
            isJointAccountsAvailable: isJointAccountsAvailable
        )
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

    static func operation(
        status: JointAccountOperationStatus = .awaitingSignatures,
        signatures: [JointAccountOperation.Signature] = [signed]
    ) -> JointAccountOperation {
        JointAccountOperation(
            id: operationId,
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
