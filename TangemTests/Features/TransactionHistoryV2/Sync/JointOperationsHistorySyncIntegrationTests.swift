//
//  JointOperationsHistorySyncIntegrationTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemAppDatabase
import TangemFoundation
@testable import Tangem
@testable import BlockchainSdk

@Suite("Joint operations history sync into the database", .timeLimit(.minutes(1)))
struct JointOperationsHistorySyncIntegrationTests {
    @Test("Operations of the archive and the delta reach the database, and the cursors outlive the service")
    func archiveAndDeltaReachDatabase() async throws {
        let apiService = FakeTangemApiService()
        apiService.getJointOperationsHistoryHandler = { _ in
            try Self.decode(JointAccountsDTO.Response.OperationsHistory.self, json: """
            { "items": [\(Self.operationJSON(id: "op-1"))],
              "pagination": { "endCursor": "archive-1", "startDeltaCursor": "delta-0", "hasMore": false } }
            """)
        }
        apiService.getJointOperationsHistoryDeltaHandler = { _ in
            try Self.decode(JointAccountsDTO.Response.OperationsHistoryDelta.self, json: """
            { "items": [\(Self.operationJSON(id: "op-2"))],
              "pagination": { "startCursor": "delta-1", "hasMore": false } }
            """)
        }

        let (records, archiveCursor, deltaCursor, isInitialSyncDone) = try await withInjected(apiService: apiService) {
            let syncService = makeSyncService()
            await syncService.syncInitial()
            await syncService.syncDelta()

            let storage = CommonJointOperationsSyncMetadataStorage(userWalletId: Self.userWalletId)

            return (
                await records(reaching: 2),
                try await storage.archiveCursor(),
                try await storage.deltaCursor(),
                try await storage.isInitialSyncDone()
            )
        }

        #expect(Set(records.map(\.groupingId)) == ["op-1", "op-2"])
        #expect(archiveCursor == "archive-1")
        #expect(deltaCursor == "delta-1")
        #expect(isInitialSyncDone)
    }

    @Test("A wallet without active joint accounts never calls the joint history endpoints")
    func walletWithoutJointAccountsDoesNotCallEndpoints() async {
        let apiService = FakeTangemApiService()
        let callsCount = OSAllocatedUnfairLock(initialState: 0)
        apiService.getJointOperationsHistoryHandler = { _ in
            callsCount.withLock { $0 += 1 }
            throw "Not expected to be called"
        }
        apiService.getJointOperationsHistoryDeltaHandler = { _ in
            callsCount.withLock { $0 += 1 }
            throw "Not expected to be called"
        }

        await withInjected(apiService: apiService) {
            let syncService = makeSyncService(jointAccounts: [])
            await syncService.syncInitial()
            await syncService.syncDelta()
        }

        #expect(callsCount.withLock { $0 } == 0)
    }
}

// MARK: - Helpers

private extension JointOperationsHistorySyncIntegrationTests {
    static let userWalletId = JointAccountCompositionFixture.userWalletId
    static let safeAddress = "0x8f3ac21b7e5f4552091a69125d5dfcb7b8c26590"

    func makeSyncService(
        jointAccounts: [StoredJointAccount] = [
            JointAccountCompositionFixture.storedAccount(status: .active(safeAddress: Self.safeAddress), membersCount: 2, members: []),
        ]
    ) -> JointOperationsHistorySyncService {
        let syncMetadataStorage = CommonJointOperationsSyncMetadataStorage(userWalletId: Self.userWalletId)

        return JointOperationsHistorySyncService(
            networkService: CommonJointOperationsHistoryNetworkService(
                networkService: CommonJointAccountsNetworkService(userWalletId: Self.userWalletId),
                writer: CommonTransactionHistoryRecordsWriter(),
                syncMetadataStorage: syncMetadataStorage,
                pageSize: 100
            ),
            syncMetadataStorage: syncMetadataStorage,
            jointAccountsRepository: JointAccountsRepositoryStub(jointAccounts: jointAccounts)
        )
    }

    func records(reaching count: Int) async -> [TransactionHistoryRecordsReader.Record] {
        let reader = CommonTransactionHistoryRecordsReader()
        defer { withExtendedLifetime(reader) {} }

        let updates = reader.updates(
            for: WalletModelId(tokenItem: .blockchain(.init(.base(testnet: false), derivationPath: nil))),
            walletModelAddressesPublisher: CurrentValueSubject<[String], Never>([Self.safeAddress])
        )

        for await records in updates where records.count >= count {
            return records
        }

        return []
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

    static func decode<T: Decodable>(_ type: T.Type, json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    static func operationJSON(id: String) -> String {
        """
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
          "safeAddress": "\(safeAddress)",
          "txHash": "0x4e3a3754410177e6937ef1f84bba68ea139e8d1a2258c5f85db9f1cd715a1bdd",
          "finishedAt": "2026-09-08T09:24:02.000Z", "cancelReason": null
        }
        """
    }
}
