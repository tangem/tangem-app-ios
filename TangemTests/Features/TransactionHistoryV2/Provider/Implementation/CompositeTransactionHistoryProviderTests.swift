//
//  CompositeTransactionHistoryProviderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemExpress
import TangemFoundation
@testable import Tangem

@Suite("CompositeTransactionHistoryProvider")
struct CompositeTransactionHistoryProviderTests {
    @Test("A failing joint initial sync doesn't keep the Express one from running")
    func failingJointInitialSyncDoesNotStopExpress() async {
        let (sut, expressProvider, jointNetworkService) = makeSUT(isJointInitialSyncDone: false)

        await sut.syncInitial()

        #expect(expressProvider.calls == [.initial])
        #expect(jointNetworkService.initialCallsCount == 1)
    }

    @Test("A failing joint delta sync doesn't keep the Express one from running")
    func failingJointDeltaSyncDoesNotStopExpress() async {
        let (sut, expressProvider, jointNetworkService) = makeSUT(isJointInitialSyncDone: true)

        await sut.syncDelta()

        #expect(expressProvider.calls == [.delta])
        #expect(jointNetworkService.deltaCallsCount == 1)
    }

    @Test("A user-initiated sync runs the Express one and the joint delta")
    func userInitiatedSyncRunsExpressAndJointDelta() async {
        let (sut, expressProvider, jointNetworkService) = makeSUT(isJointInitialSyncDone: true)

        await sut.syncUserInitiated(.pullToRefresh)

        #expect(expressProvider.calls == [.userInitiated(.pullToRefresh)])
        #expect(jointNetworkService.deltaCallsCount == 1)
    }

    @Test("The state is syncing while either side syncs")
    func stateIsSyncingWhileEitherSyncs() async {
        let expressSyncing = makeSUT(expressState: .syncing(.delta), jointOperationsState: .idle(.ready))
        let jointSyncing = makeSUT(expressState: .idle(.ready), jointOperationsState: .syncing(.initial))
        let jointSyncingWhileExpressFailed = makeSUT(expressState: Self.failed, jointOperationsState: .syncing(.initial))

        #expect(Self.syncKind(of: await expressSyncing.state) == .delta)
        #expect(Self.syncKind(of: await jointSyncing.state) == .initial)
        #expect(Self.syncKind(of: await jointSyncingWhileExpressFailed.state) == .initial)
    }

    @Test("The state names the side that failed")
    func stateNamesFailedSide() async {
        let expressFailed = makeSUT(expressState: Self.failed, jointOperationsState: .idle(.ready))
        let jointFailed = makeSUT(expressState: .idle(.ready), jointOperationsState: Self.failed)

        #expect(Self.failedProviders(of: await expressFailed.state) == ["express"])
        #expect(Self.failedProviders(of: await jointFailed.state) == ["jointOperations"])
    }

    @Test("The state is the Express failure when both sides failed")
    func stateIsExpressFailureWhenBothFailed() async {
        let sut = makeSUT(expressState: Self.failed, jointOperationsState: Self.failed)

        #expect(Self.isTransportFailure(await sut.state))
    }

    @Test("The state is ready once both sides are, and an idle joint side doesn't hold the Express one back")
    func stateIsReadyWhenBothAreIdle() async {
        let bothReady = makeSUT(expressState: .idle(.ready), jointOperationsState: .idle(.ready))
        let jointNeverSynced = makeSUT(expressState: .idle(.ready), jointOperationsState: .idle(.neverSynced))

        #expect(Self.idleReason(of: await bothReady.state) == .ready)
        #expect(Self.idleReason(of: await jointNeverSynced.state) == .ready)
    }

    @Test("A failed joint sync shows in the provider's state as a partial failure")
    func failedJointSyncShowsAsPartialFailure() async {
        let (sut, _, _) = makeSUT(isJointInitialSyncDone: false)

        await sut.syncInitial()

        #expect(Self.failedProviders(of: await sut.state) == ["jointOperations"])
    }

    @Test("The provider identifies itself as the Express one")
    func identifiesAsExpressProvider() {
        let (sut, expressProvider, _) = makeSUT(isJointInitialSyncDone: true)

        #expect(sut.id == AnyHashable(expressProvider.id))
    }
}

// MARK: - Helpers

private extension CompositeTransactionHistoryProviderTests {
    static let failed = TransactionHistorySyncState.failed(.init(reason: .transport(message: "offline"), syncKind: .delta))

    static func syncKind(of state: TransactionHistorySyncState) -> TransactionHistorySyncState.Kind? {
        guard case .syncing(let kind) = state else {
            return nil
        }

        return kind
    }

    static func idleReason(of state: TransactionHistorySyncState) -> TransactionHistorySyncState.IdleReason? {
        guard case .idle(let reason) = state else {
            return nil
        }

        return reason
    }

    static func isTransportFailure(_ state: TransactionHistorySyncState) -> Bool {
        guard case .failed(let failure) = state, case .transport = failure.reason else {
            return false
        }

        return true
    }

    func makeSUT(
        expressState: TransactionHistorySyncState,
        jointOperationsState: TransactionHistorySyncState
    ) -> CompositeTransactionHistoryProvider {
        CompositeTransactionHistoryProvider(
            expressProvider: ExpressProviderStub(state: expressState),
            jointOperationsSyncService: JointOperationsHistorySyncingStub(state: jointOperationsState)
        )
    }

    static func failedProviders(of state: TransactionHistorySyncState) -> [String]? {
        guard case .failed(let failure) = state, case .partialFailure(let failedProviders) = failure.reason else {
            return nil
        }

        return failedProviders
    }

    func makeSUT(
        isJointInitialSyncDone: Bool
    ) -> (CompositeTransactionHistoryProvider, ExpressProviderStub, JointOperationsHistoryNetworkServiceStub) {
        let expressProvider = ExpressProviderStub()
        let jointNetworkService = JointOperationsHistoryNetworkServiceStub(error: "The joint history endpoint refused")
        let jointSyncService = JointOperationsHistorySyncService(
            networkService: jointNetworkService,
            syncMetadataStorage: JointOperationsSyncMetadataStorageStub(
                archiveCursor: nil,
                deltaCursor: nil,
                isInitialSyncDone: isJointInitialSyncDone
            ),
            jointAccountsRepository: JointAccountsRepositoryStub(jointAccounts: [
                JointAccountCompositionFixture.storedAccount(
                    status: .active(safeAddress: "0x8f3ac21b7e5f4552091a69125d5dfcb7b8c26590"),
                    membersCount: 2,
                    members: []
                ),
            ])
        )

        let sut = CompositeTransactionHistoryProvider(expressProvider: expressProvider, jointOperationsSyncService: jointSyncService)

        return (sut, expressProvider, jointNetworkService)
    }
}

// MARK: - Stubs

private final class ExpressProviderStub: TransactionHistoryProviding {
    enum Call: Equatable {
        case initial
        case delta
        case userInitiated(UserInitiatedSyncKind)
    }

    let id = "express-provider"
    let mappingQueue = DispatchQueue(label: "com.tangem.tests.ExpressProviderStub")

    private let recordedCalls = OSAllocatedUnfairLock(initialState: [Call]())

    var calls: [Call] {
        recordedCalls.withLock { $0 }
    }

    private let syncState: TransactionHistorySyncState

    init(state: TransactionHistorySyncState = .idle(.ready)) {
        syncState = state
    }

    var state: TransactionHistorySyncState { get async { syncState } }
    var stateUpdates: AsyncStream<TransactionHistorySyncState> { AsyncStream { $0.finish() } }

    func syncInitial() async {
        recordedCalls.withLock { $0.append(.initial) }
    }

    func syncDelta() async {
        recordedCalls.withLock { $0.append(.delta) }
    }

    func syncUserInitiated(_ kind: UserInitiatedSyncKind) async {
        recordedCalls.withLock { $0.append(.userInitiated(kind)) }
    }

    func enrich(with transaction: SentSwapTransactionData) async {}
    func enrich(with transaction: SentOnrampTransactionData) async {}
    func enrich(with transaction: ExchangeTransaction) async {}
    func enrich(with transaction: OnrampTransaction) async {}

    func historyUpdates(
        for walletModelId: WalletModelId,
        walletModelAddressesPublisher: some Publisher<[String], Never>
    ) -> AsyncStream<[TransactionHistoryRecordsReader.Record]> {
        AsyncStream { $0.finish() }
    }
}

private struct JointOperationsHistorySyncingStub: JointOperationsHistorySyncing {
    let state: TransactionHistorySyncState

    var stateUpdates: AsyncStream<TransactionHistorySyncState> { AsyncStream { $0.finish() } }

    func syncInitial() async {}
    func syncDelta() async {}
    func syncUserInitiated(_ kind: UserInitiatedSyncKind) async {}
}
