//
//  CommonJointAccountsNetworkServiceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CommonJointAccountsNetworkService")
struct CommonJointAccountsNetworkServiceTests {
    private static let userWalletId = UserWalletId(value: Data(repeating: 0xCD, count: 32))
    private static let listingETag = "listing-etag"

    @Test("A write drops the listing's tag, so the next read is answered in full rather than with a 304")
    func aWriteDropsTheListingETag() async throws {
        let apiService = FakeTangemApiService()
        let eTagStorage = ETagStorageStub()
        eTagStorage.saveETag(Self.listingETag, for: .jointAccounts(walletId: Self.userWalletId))

        apiService.rejectJointAccountOperationHandler = { _ in nil }

        try await Self.withInjected(apiService: apiService, eTagStorage: eTagStorage) {
            let sut = CommonJointAccountsNetworkService(userWalletId: Self.userWalletId)

            _ = try await sut.rejectOperation(id: "operation-id")
        }

        #expect(eTagStorage.loadETag(for: .jointAccounts(walletId: Self.userWalletId)) == nil)
    }

    @Test("A read sends the tag it is given and hands back the tag of the answer without keeping it", arguments: [nil, "known-etag"] as [String?])
    func aReadPassesTheETagsThrough(knownETag: String?) async throws {
        let apiService = FakeTangemApiService()
        let eTagStorage = ETagStorageStub()
        var sentETags: [String?] = []

        apiService.getJointAccountsHandler = { sentETag in
            sentETags.append(sentETag)
            return (eTag: Self.listingETag, accounts: try Self.emptyListing())
        }

        let state = try await Self.withInjected(apiService: apiService, eTagStorage: eTagStorage) {
            try await CommonJointAccountsNetworkService(userWalletId: Self.userWalletId).getJointAccounts(knownETag: knownETag)
        }

        guard case .changed(_, let returnedETag) = state else {
            Issue.record("Expected a changed listing, got \(state)")
            return
        }

        #expect(sentETags == [knownETag])
        #expect(returnedETag == Self.listingETag)
        #expect(eTagStorage.loadETag(for: .jointAccounts(walletId: Self.userWalletId)) == nil)
    }

    @Test("A write the endpoint refused changes nothing on the backend, so the tag stays")
    func aFailedWriteKeepsTheListingETag() async throws {
        let apiService = FakeTangemApiService()
        let eTagStorage = ETagStorageStub()
        eTagStorage.saveETag(Self.listingETag, for: .jointAccounts(walletId: Self.userWalletId))

        apiService.rejectJointAccountOperationHandler = { _ in throw TestError.refused }

        await Self.withInjected(apiService: apiService, eTagStorage: eTagStorage) {
            let sut = CommonJointAccountsNetworkService(userWalletId: Self.userWalletId)

            await #expect(throws: TestError.refused) {
                try await sut.rejectOperation(id: "operation-id")
            }
        }

        #expect(eTagStorage.loadETag(for: .jointAccounts(walletId: Self.userWalletId)) == Self.listingETag)
    }

    @Test("A single operation read with the tag it was last seen under is answered with no body")
    func anUnchangedOperationIsNotModified() async throws {
        let apiService = FakeTangemApiService()
        var sentETags: [String?] = []

        apiService.getJointOperationHandler = { _, sentETag in
            sentETags.append(sentETag)
            return nil
        }

        let result = try await Self.withInjected(apiService: apiService, eTagStorage: ETagStorageStub()) {
            try await CommonJointAccountsNetworkService(userWalletId: Self.userWalletId).getOperation(id: "operation-id", knownETag: "operation-etag")
        }

        #expect(result == .notModified)
        #expect(sentETags == ["operation-etag"])
    }

    @Test("A single operation read hands back the operation with the tag of the answer")
    func aChangedOperationIsRead() async throws {
        let apiService = FakeTangemApiService()

        apiService.getJointOperationHandler = { operationId, _ in
            let operation = try Self.historyOperation(id: operationId)
            return (eTag: "operation-etag", operation: operation)
        }

        let result = try await Self.withInjected(apiService: apiService, eTagStorage: ETagStorageStub()) {
            try await CommonJointAccountsNetworkService(userWalletId: Self.userWalletId).getOperation(id: "operation-id", knownETag: nil)
        }

        guard case .modified(let item, let eTag) = result else {
            Issue.record("Expected a changed operation, got \(result)")
            return
        }

        #expect(item.operation.id == "operation-id")
        #expect(item.operation.status == .executed)
        #expect(eTag == "operation-etag")
    }

    @Test(
        "A refusal of a single operation read names its reason",
        arguments: [
            (TangemAPIError.ErrorCode.notFound, JointOperationError.operationNotFound),
            (.forbidden, .notAMember),
        ]
    )
    func aRefusedOperationReadIsNamed(code: TangemAPIError.ErrorCode, expected: JointOperationError) async {
        let apiService = FakeTangemApiService()

        apiService.getJointOperationHandler = { _, _ in throw TangemAPIError(code: code) }

        await Self.withInjected(apiService: apiService, eTagStorage: ETagStorageStub()) {
            let sut = CommonJointAccountsNetworkService(userWalletId: Self.userWalletId)

            await #expect(throws: expected) {
                try await sut.getOperation(id: "operation-id", knownETag: nil)
            }
        }
    }

    @Test(
        "A refusal of a new operation names the reason the endpoint gave, one this version has never heard of included",
        arguments: [
            ("UNSUPPORTED_CHAIN", JointOperationRefusal.unsupportedChain),
            ("NONCE_MISMATCH", .nonceMismatch),
            ("INVALID_BASE_GAS", .invalidBaseGas),
            ("GAS_PRICE_TOO_LOW", .gasPriceTooLow),
            ("GAS_PRICE_TOO_HIGH", .gasPriceTooHigh),
            ("GAS_TOKEN_NOT_ALLOWED", .gasTokenNotAllowed),
            ("INVALID_REFUND_RECEIVER", .invalidRefundReceiver),
            ("INVALID_SAFE_OPERATION", .invalidSafeOperation),
            ("INVALID_SAFE_ADDRESS", .invalidSafeAddress),
            ("STALE_NONCE", .unknown("STALE_NONCE")),
        ]
    )
    func aRefusedOperationIsNamed(reasonCode: String, expected: JointOperationRefusal) async {
        let apiService = FakeTangemApiService()

        apiService.createJointAccountOperationHandler = { _ in
            throw TangemAPIError(code: .badRequest, message: "The request has nonce 7. The Safe is at nonce 8", reasonCode: reasonCode)
        }

        await Self.withInjected(apiService: apiService, eTagStorage: ETagStorageStub()) {
            let sut = CommonJointAccountsNetworkService(userWalletId: Self.userWalletId)

            await #expect(throws: JointOperationError.refused(expected)) {
                try await sut.createOperation(Self.operationRequest())
            }
        }
    }

    @Test("A new operation in a network that already carries an unfinished one is refused as the network being busy")
    func aConflictingOperationIsRefusedAsNetworkBusy() async {
        let apiService = FakeTangemApiService()

        apiService.createJointAccountOperationHandler = { _ in throw TangemAPIError(code: .conflict) }

        await Self.withInjected(apiService: apiService, eTagStorage: ETagStorageStub()) {
            let sut = CommonJointAccountsNetworkService(userWalletId: Self.userWalletId)

            await #expect(throws: JointOperationError.networkBusy) {
                try await sut.createOperation(Self.operationRequest())
            }
        }
    }

    @Test(
        "A refusal of a new operation that names no reason reaches the caller as it came",
        arguments: [
            TangemAPIError(code: .badRequest),
            TangemAPIError(code: .notFound, reasonCode: "NONCE_MISMATCH"),
        ]
    )
    func anUnnamedRefusalPassesThrough(refusal: TangemAPIError) async throws {
        let apiService = FakeTangemApiService()

        apiService.createJointAccountOperationHandler = { _ in throw refusal }

        try await Self.withInjected(apiService: apiService, eTagStorage: ETagStorageStub()) {
            let sut = CommonJointAccountsNetworkService(userWalletId: Self.userWalletId)

            let error = try await #require(throws: TangemAPIError.self) {
                try await sut.createOperation(Self.operationRequest())
            }

            #expect(error.code == refusal.code)
            #expect(error.reasonCode == refusal.reasonCode)
        }
    }

    @Test("A history read passes its cursor and page size through and leaves the listing's tag alone")
    func aHistoryReadKeepsTheListingETag() async throws {
        let apiService = FakeTangemApiService()
        let eTagStorage = ETagStorageStub()
        eTagStorage.saveETag(Self.listingETag, for: .jointAccounts(walletId: Self.userWalletId))
        var requests: [JointAccountsDTO.Request.OperationsHistory] = []

        apiService.getJointOperationsHistoryHandler = { request in
            requests.append(request)
            return try Self.emptyHistory()
        }

        let page = try await Self.withInjected(apiService: apiService, eTagStorage: eTagStorage) {
            try await CommonJointAccountsNetworkService(userWalletId: Self.userWalletId).getOperationsHistory(afterCursor: "cursor", limit: 100)
        }

        #expect(page.items.isEmpty)
        #expect(!page.hasMore)
        #expect(requests.map(\.afterCursor) == ["cursor"])
        #expect(requests.map(\.limit) == [100])
        #expect(eTagStorage.loadETag(for: .jointAccounts(walletId: Self.userWalletId)) == Self.listingETag)
    }
}

// MARK: - Private

private extension CommonJointAccountsNetworkServiceTests {
    enum TestError: Error {
        case refused
    }

    static func emptyListing() throws -> JointAccountsDTO.Response.JointAccounts {
        try JSONDecoder().decode(JointAccountsDTO.Response.JointAccounts.self, from: Data(#"{ "jointAccounts": [] }"#.utf8))
    }

    static func emptyHistory() throws -> JointAccountsDTO.Response.OperationsHistory {
        let json = #"{ "items": [], "pagination": { "endCursor": null, "startDeltaCursor": null, "hasMore": false } }"#

        return try JSONDecoder().decode(JointAccountsDTO.Response.OperationsHistory.self, from: Data(json.utf8))
    }

    static func historyOperation(id: String) throws -> JointAccountsDTO.Response.HistoryOperation {
        let json = """
        {
          "operationId": "\(id)", "chainId": 8453, "status": "executed",
          "safeTx": {
            "to": "0x2b5ad5c4795c026514f8317c7a215e218dccd6cf", "value": "1000000000000000", "data": "0x", "operation": 0,
            "safeTxGas": "65000", "baseGas": "30000", "gasPrice": "2000000000",
            "gasToken": "0x0000000000000000000000000000000000000000",
            "refundReceiver": "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf", "nonce": "7"
          },
          "initiator": "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf", "threshold": 2,
          "votes": [],
          "createdAt": "2026-09-08T09:20:37.000Z",
          "cryptoAccountId": "A7B3C9D2E4F60718293A4B5C6D7E8F9A0B1C2D3E4F5061728394A5B6C7D8E9F0",
          "safeAddress": "0x8f3ac21b7e5f4552091a69125d5dfcb7b8c26590",
          "txHash": "0x4e3a3754410177e6937ef1f84bba68ea139e8d1a2258c5f85db9f1cd715a1bdd",
          "finishedAt": "2026-09-08T09:24:02.000Z", "cancelReason": null
        }
        """

        return try JSONDecoder().decode(JointAccountsDTO.Response.HistoryOperation.self, from: Data(json.utf8))
    }

    static func operationRequest() -> JointAccountOperationRequest {
        JointAccountOperationRequest(
            safeAddress: "0x8f3ac21b7e5f4552091a69125d5dfcb7b8c26590",
            chainId: 1,
            safeTransaction: JointAccountCompositionFixture.coinTransfer().safeTransaction,
            signature: Data(repeating: 0x1B, count: 65)
        )
    }

    static func withInjected<T>(
        apiService: TangemApiService,
        eTagStorage: ETagStorage,
        operation: () async throws -> T
    ) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousApiService = InjectedValues[\.tangemApiService]
            let previousETagStorage = InjectedValues[\.eTagStorage]
            InjectedValues[\.tangemApiService] = apiService
            InjectedValues[\.eTagStorage] = eTagStorage
            defer {
                InjectedValues[\.tangemApiService] = previousApiService
                InjectedValues[\.eTagStorage] = previousETagStorage
            }

            return try await operation()
        }
    }
}

private final class ETagStorageStub: ETagStorage {
    private let eTags = OSAllocatedUnfairLock<[String: String]>(initialState: [:])

    func initialize() {}

    func loadETag(for key: ETagStorageKey) -> String? {
        eTags.withLock { $0[Self.rawKey(key)] }
    }

    func saveETag(_ eTag: String, for key: ETagStorageKey) {
        eTags.withLock { $0[Self.rawKey(key)] = eTag }
    }

    func clearETag(for key: ETagStorageKey) {
        eTags.withLock { $0[Self.rawKey(key)] = nil }
    }

    private static func rawKey(_ key: ETagStorageKey) -> String {
        switch key {
        case .accounts(let walletId): "accounts_\(walletId.stringValue)"
        case .addressBook(let walletId): "addressBook_\(walletId.stringValue)"
        case .jointAccounts(let walletId): "jointAccounts_\(walletId.stringValue)"
        }
    }
}
