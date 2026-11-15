//
//  TransactionHistoryProviderResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemAppDatabase
import TangemFoundation
@testable import Tangem

@Suite("TransactionHistoryProviderResolver")
struct TransactionHistoryProviderResolverTests {
    @Test("With joint accounts off the provider is the Express sync service and the joint history sync is a no-op")
    func expressOnlyWhileJointAccountsAreOff() async {
        let sut = makeSUT(isJointAccountsAvailable: false)

        let provider = await sut.provider()
        let jointOperationsSyncService = await sut.jointOperationsSyncService()

        #expect(provider is TransactionHistoryWalletSyncService)
        #expect(jointOperationsSyncService is MockJointOperationsHistorySyncService)
    }

    @Test("With joint accounts on the provider and the finished operations share one joint history sync")
    func providerAndJointSyncShareOneService() async throws {
        let sut = makeSUT(isJointAccountsAvailable: true)

        let provider = try #require(await sut.provider() as? CompositeTransactionHistoryProvider)
        let jointOperationsSyncService = try #require(await sut.jointOperationsSyncService() as? JointOperationsHistorySyncService)
        let providerJointOperationsSyncService = try #require(
            Mirror(reflecting: provider).children.first { $0.label == "jointOperationsSyncService" }?.value as? JointOperationsHistorySyncService
        )

        #expect(providerJointOperationsSyncService === jointOperationsSyncService)
    }

    @Test("The delta sync of the resolver reaches the joint history only while joint accounts are on", arguments: [true, false])
    func deltaSyncReachesJointHistory(isJointAccountsAvailable: Bool) async throws {
        let apiService = FakeTangemApiService()
        let deltaRequestsCount = OSAllocatedUnfairLock(initialState: 0)
        apiService.getJointOperationsHistoryDeltaHandler = { _ in
            deltaRequestsCount.withLock { $0 += 1 }
            return try JSONDecoder().decode(
                JointAccountsDTO.Response.OperationsHistoryDelta.self,
                from: Data(#"{ "items": [], "pagination": { "startCursor": null, "hasMore": false } }"#.utf8)
            )
        }

        try await withInjected(apiService: apiService) {
            try await CommonJointOperationsSyncMetadataStorage(userWalletId: Self.userWalletId).setIsInitialSyncDone(true)
            let sut = makeSUT(isJointAccountsAvailable: isJointAccountsAvailable, jointAccounts: [Self.activeJointAccount])

            await sut.syncDelta()
        }

        #expect(deltaRequestsCount.withLock { $0 } == (isJointAccountsAvailable ? 1 : 0))
    }
}

// MARK: - Helpers

private extension TransactionHistoryProviderResolverTests {
    static let userWalletId = JointAccountCompositionFixture.userWalletId

    static let activeJointAccount = JointAccountCompositionFixture.storedAccount(
        status: .active(safeAddress: "0x8f3ac21b7e5f4552091a69125d5dfcb7b8c26590"),
        membersCount: 2,
        members: []
    )

    func makeSUT(isJointAccountsAvailable: Bool, jointAccounts: [StoredJointAccount] = []) -> TransactionHistoryProviderResolver {
        TransactionHistoryProviderResolver(
            userWalletId: Self.userWalletId,
            refcodeProvider: nil,
            jointAccountsRepository: JointAccountsRepositoryStub(jointAccounts: jointAccounts),
            isJointAccountsAvailable: isJointAccountsAvailable
        )
    }

    func withInjected<T>(apiService: TangemApiService, operation: () async throws -> T) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousApiService = InjectedValues[\.tangemApiService]
            let previousAppDatabase = InjectedValues[\.appDatabase]
            InjectedValues[\.tangemApiService] = apiService
            InjectedValues[\.appDatabase] = AppDatabase.makeWithInMemoryStorage(migrationHelper: CommonAppDatabaseMigrationHelper())
            defer {
                InjectedValues[\.tangemApiService] = previousApiService
                InjectedValues[\.appDatabase] = previousAppDatabase
            }

            return try await operation()
        }
    }
}
