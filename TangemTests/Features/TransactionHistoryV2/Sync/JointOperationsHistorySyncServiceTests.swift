//
//  JointOperationsHistorySyncServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("JointOperationsHistorySyncService")
struct JointOperationsHistorySyncServiceTests {
    @Test("Nothing is synced without an active joint account", arguments: [
        [JointAccountStatus](),
        [.pending, .confirming(safeAddress: nil), .cancelled, .unknown],
    ])
    func nothingIsSyncedWithoutActiveJointAccount(statuses: [JointAccountStatus]) async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: nil)
        let (sut, _) = makeSUT(networkService: networkService, accountStatuses: statuses, isInitialSyncDone: true)

        await sut.syncInitial()
        await sut.syncDelta()
        await sut.syncUserInitiated(.pullToRefresh)

        #expect(networkService.initialCallsCount == 0)
        #expect(networkService.deltaCallsCount == 0)
    }

    @Test("The delta waits for the initial sync, which runs only once")
    func deltaWaitsForInitialSync() async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: nil)
        let (sut, _) = makeSUT(networkService: networkService, isInitialSyncDone: false)

        await sut.syncDelta()
        let deltaCallsBeforeInitialSync = networkService.deltaCallsCount
        await sut.syncInitial()
        await sut.syncInitial()
        await sut.syncDelta()

        #expect(deltaCallsBeforeInitialSync == 0)
        #expect(networkService.initialCallsCount == 1)
        #expect(networkService.deltaCallsCount == 1)
    }

    @Test("A stored finished initial sync is not repeated")
    func storedFinishedInitialSyncIsNotRepeated() async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: nil)
        let (sut, _) = makeSUT(networkService: networkService, isInitialSyncDone: true)

        await sut.syncInitial()
        await sut.syncDelta()

        #expect(networkService.initialCallsCount == 0)
        #expect(networkService.deltaCallsCount == 1)
    }

    @Test("A finished sync leaves the service ready")
    func finishedSyncLeavesServiceReady() async {
        let (sut, _) = makeSUT(networkService: JointOperationsHistoryNetworkServiceStub(error: nil), isInitialSyncDone: false)

        await sut.syncInitial()

        #expect(Self.isReady(await sut.state))
    }

    @Test("A failed sync is reported in the state and retried on the next call")
    func failedSyncIsReportedAndRetried() async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: "The joint history endpoint refused")
        let (sut, _) = makeSUT(networkService: networkService, isInitialSyncDone: false)

        await sut.syncInitial()
        let state = await sut.state
        await sut.syncInitial()

        #expect(Self.failureReason(of: state) == .transport)
        #expect(networkService.initialCallsCount == 2)
    }

    @Test("A cancelled initial sync is neither a failure nor a finished initial sync")
    func cancelledInitialSyncIsNoOp() async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: CancellationError())
        let (sut, storage) = makeSUT(networkService: networkService, isInitialSyncDone: false)

        await sut.syncInitial()
        let state = await sut.state
        await sut.syncDelta()

        #expect(Self.isNeverSynced(state))
        #expect(networkService.deltaCallsCount == 0)
        #expect(storage.clearCallsCount == 0)
    }

    @Test("A cancelled delta is neither a failure nor a reason to throttle the next pull-to-refresh")
    func cancelledDeltaIsNoOp() async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: CancellationError())
        let (sut, storage) = makeSUT(networkService: networkService, isInitialSyncDone: true)

        await sut.syncDelta()
        let stateAfterDelta = await sut.state
        await sut.syncUserInitiated(.pullToRefresh)
        let stateAfterPullToRefresh = await sut.state
        await sut.syncUserInitiated(.pullToRefresh)

        #expect(Self.isNeverSynced(stateAfterDelta))
        #expect(Self.isNeverSynced(stateAfterPullToRefresh))
        #expect(networkService.deltaCallsCount == 3)
        #expect(storage.clearCallsCount == 0)
    }

    @Test("A refused archive cursor resets the sync state, and the next sync starts the archive over")
    func refusedArchiveCursorResetsSyncState() async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: TangemAPIError(code: .badRequest))
        let (sut, storage) = makeSUT(
            networkService: networkService,
            storage: JointOperationsSyncMetadataStorageStub(archiveCursor: "archive-1", deltaCursor: "delta-0")
        )

        await sut.syncInitial()
        let state = await sut.state
        await sut.syncInitial()

        #expect(Self.failureReason(of: state) == .cursorReset)
        #expect(storage.clearCallsCount == 2)
        #expect(storage.archiveCursorValue == nil)
        #expect(storage.deltaCursorValue == nil)
        #expect(networkService.initialCallsCount == 2)
    }

    @Test("A refused delta cursor resets the sync state, so the archive runs again before any delta")
    func refusedDeltaCursorResetsSyncState() async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: TangemAPIError(code: .badRequest))
        let (sut, storage) = makeSUT(
            networkService: networkService,
            storage: JointOperationsSyncMetadataStorageStub(archiveCursor: "archive-1", deltaCursor: "delta-0", isInitialSyncDone: true)
        )

        await sut.syncDelta()
        await sut.syncDelta()
        await sut.syncInitial()

        #expect(storage.clearCallsCount == 2)
        #expect(storage.deltaCursorValue == nil)
        #expect(!storage.isInitialSyncDoneValue)
        #expect(networkService.deltaCallsCount == 1)
        #expect(networkService.initialCallsCount == 1)
    }

    @Test("Any other failure leaves the sync state as it was")
    func otherFailureLeavesSyncStateAlone() async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: TangemAPIError(code: .notFound))
        let (sut, storage) = makeSUT(
            networkService: networkService,
            storage: JointOperationsSyncMetadataStorageStub(archiveCursor: "archive-1", deltaCursor: "delta-0", isInitialSyncDone: true)
        )

        await sut.syncDelta()
        await sut.syncDelta()

        #expect(storage.clearCallsCount == 0)
        #expect(storage.deltaCursorValue == "delta-0")
        #expect(storage.isInitialSyncDoneValue)
        #expect(networkService.deltaCallsCount == 2)
    }

    @Test("A pull-to-refresh right after a successful one is throttled")
    func pullToRefreshIsThrottled() async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: nil)
        let (sut, _) = makeSUT(networkService: networkService, isInitialSyncDone: true)

        await sut.syncUserInitiated(.pullToRefresh)
        await sut.syncUserInitiated(.pullToRefresh)

        #expect(networkService.deltaCallsCount == 1)
    }

    @Test("A failed pull-to-refresh doesn't throttle the next one")
    func failedPullToRefreshIsNotThrottled() async {
        let networkService = JointOperationsHistoryNetworkServiceStub(error: TangemAPIError(code: .notFound))
        let (sut, _) = makeSUT(networkService: networkService, isInitialSyncDone: true)

        await sut.syncUserInitiated(.pullToRefresh)
        await sut.syncUserInitiated(.pullToRefresh)

        #expect(networkService.deltaCallsCount == 2)
    }
}

// MARK: - Helpers

private extension JointOperationsHistorySyncServiceTests {
    enum FailureReason: Equatable {
        case cursorReset
        case transport
        case other
    }

    static func isReady(_ state: TransactionHistorySyncState) -> Bool {
        guard case .idle(.ready) = state else {
            return false
        }

        return true
    }

    static func isNeverSynced(_ state: TransactionHistorySyncState) -> Bool {
        guard case .idle(.neverSynced) = state else {
            return false
        }

        return true
    }

    static func failureReason(of state: TransactionHistorySyncState) -> FailureReason? {
        guard case .failed(let failure) = state else {
            return nil
        }

        switch failure.reason {
        case .cursorReset: return .cursorReset
        case .transport: return .transport
        case .partialFailure, .server: return .other
        }
    }

    func makeSUT(
        networkService: JointOperationsHistoryNetworkServiceStub,
        accountStatuses: [JointAccountStatus] = [.active(safeAddress: "0x8f3ac21b7e5f4552091a69125d5dfcb7b8c26590")],
        isInitialSyncDone: Bool
    ) -> (JointOperationsHistorySyncService, JointOperationsSyncMetadataStorageStub) {
        makeSUT(
            networkService: networkService,
            accountStatuses: accountStatuses,
            storage: JointOperationsSyncMetadataStorageStub(archiveCursor: nil, deltaCursor: nil, isInitialSyncDone: isInitialSyncDone)
        )
    }

    func makeSUT(
        networkService: JointOperationsHistoryNetworkServiceStub,
        accountStatuses: [JointAccountStatus] = [.active(safeAddress: "0x8f3ac21b7e5f4552091a69125d5dfcb7b8c26590")],
        storage: JointOperationsSyncMetadataStorageStub
    ) -> (JointOperationsHistorySyncService, JointOperationsSyncMetadataStorageStub) {
        let sut = JointOperationsHistorySyncService(
            networkService: networkService,
            syncMetadataStorage: storage,
            jointAccountsRepository: JointAccountsRepositoryStub(jointAccounts: accountStatuses.map { status in
                JointAccountCompositionFixture.storedAccount(status: status, membersCount: 2, members: [])
            })
        )

        return (sut, storage)
    }
}
