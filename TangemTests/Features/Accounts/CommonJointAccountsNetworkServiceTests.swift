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
}

// MARK: - Private

private extension CommonJointAccountsNetworkServiceTests {
    enum TestError: Error {
        case refused
    }

    static func emptyListing() throws -> JointAccountsDTO.Response.JointAccounts {
        try JSONDecoder().decode(JointAccountsDTO.Response.JointAccounts.self, from: Data(#"{ "jointAccounts": [] }"#.utf8))
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
