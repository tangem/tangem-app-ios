//
//  CommonJointOperationsHistoryNetworkServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CommonJointOperationsHistoryNetworkService")
struct CommonJointOperationsHistoryNetworkServiceTests {
    @Test("The archive is paged through, the delta cursor is taken from its first page only")
    func archiveIsPagedThroughWithDeltaCursorFromFirstPage() async throws {
        let networkService = JointAccountsNetworkServiceStub(historyPages: [
            Self.page(ids: ["op-1"], nextCursor: "archive-1", startDeltaCursor: "delta-0", hasMore: true),
            Self.page(ids: ["op-2"], nextCursor: "archive-2", startDeltaCursor: "delta-ignored", hasMore: false),
        ])
        let (sut, writer, storage) = makeSUT(networkService: networkService)

        try await sut.syncInitial()

        #expect(networkService.requestedHistoryCursors == [nil, "archive-1"])
        #expect(writer.savedRemoteOperationIds == [["op-1"], ["op-2"]])
        #expect(storage.archiveCursorValue == "archive-2")
        #expect(storage.deltaCursorValue == "delta-0")
        #expect(storage.isInitialSyncDoneValue)
    }

    @Test("An empty first archive page leaves the delta cursor empty and finishes the initial sync")
    func emptyArchiveLeavesDeltaCursorEmpty() async throws {
        let networkService = JointAccountsNetworkServiceStub(historyPages: [
            Self.page(ids: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false),
        ])
        let (sut, _, storage) = makeSUT(networkService: networkService)

        try await sut.syncInitial()

        #expect(storage.deltaCursorValue == nil)
        #expect(storage.isInitialSyncDoneValue)
    }

    @Test("An interrupted archive goes on from the stored cursor and keeps the stored delta cursor")
    func interruptedArchiveResumesFromStoredCursor() async throws {
        let networkService = JointAccountsNetworkServiceStub(historyPages: [
            Self.page(ids: ["op-2"], nextCursor: "archive-2", startDeltaCursor: nil, hasMore: false),
        ])
        let (sut, _, storage) = makeSUT(
            networkService: networkService,
            storage: JointOperationsSyncMetadataStorageStub(archiveCursor: "archive-1", deltaCursor: "delta-0")
        )

        try await sut.syncInitial()

        #expect(networkService.requestedHistoryCursors == ["archive-1"])
        #expect(storage.archiveCursorValue == "archive-2")
        #expect(storage.deltaCursorValue == "delta-0")
        #expect(storage.isInitialSyncDoneValue)
    }

    @Test("A page that fails to save leaves the cursors and the initial sync flag as they were")
    func failedSaveLeavesCursorsUnchanged() async {
        let networkService = JointAccountsNetworkServiceStub(historyPages: [
            Self.page(ids: ["op-1"], nextCursor: "archive-1", startDeltaCursor: "delta-0", hasMore: false),
        ])
        let (sut, writer, storage) = makeSUT(networkService: networkService, writer: JointOperationsHistoryWriterStub(isFailing: true))

        await #expect(throws: (any Error).self) {
            try await sut.syncInitial()
        }

        #expect(writer.savedRemoteOperationIds.isEmpty)
        #expect(storage.archiveCursorValue == nil)
        #expect(storage.deltaCursorValue == nil)
        #expect(!storage.isInitialSyncDoneValue)
    }

    @Test("The first archive page is retried from scratch when its delta cursor fails to be stored")
    func firstPageIsRetriedWhenDeltaCursorFailsToBeStored() async {
        let networkService = JointAccountsNetworkServiceStub(historyPages: [
            Self.page(ids: ["op-1"], nextCursor: "archive-1", startDeltaCursor: "delta-0", hasMore: true),
        ])
        let (sut, _, storage) = makeSUT(
            networkService: networkService,
            storage: JointOperationsSyncMetadataStorageStub(archiveCursor: nil, deltaCursor: nil, isDeltaCursorWriteFailing: true)
        )

        await #expect(throws: (any Error).self) {
            try await sut.syncInitial()
        }

        #expect(storage.archiveCursorValue == nil)
        #expect(!storage.isInitialSyncDoneValue)
    }

    @Test("A cancelled archive stops without finishing the initial sync")
    func cancelledArchiveDoesNotFinishInitialSync() async {
        let networkService = JointAccountsNetworkServiceStub(historyPages: [
            Self.page(ids: ["op-1"], nextCursor: "archive-1", startDeltaCursor: "delta-0", hasMore: false),
        ])
        let (sut, _, storage) = makeSUT(networkService: networkService)

        let result = await Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await sut.syncInitial()
        }.result

        #expect(throws: CancellationError.self) {
            try result.get()
        }
        #expect(!storage.isInitialSyncDoneValue)
    }

    @Test("A delta cancelled between its pages stops on the cursor of the last stored page")
    func cancelledDeltaStopsOnLastStoredCursor() async {
        let networkService = JointAccountsNetworkServiceStub(historyDeltaPages: [
            Self.page(ids: ["op-3"], nextCursor: "delta-1", startDeltaCursor: nil, hasMore: true),
            Self.page(ids: ["op-4"], nextCursor: "delta-2", startDeltaCursor: nil, hasMore: false),
        ])
        let storage = JointOperationsSyncMetadataStorageStub(archiveCursor: nil, deltaCursor: "delta-0", isInitialSyncDone: true)
        let sut = CommonJointOperationsHistoryNetworkService(
            networkService: networkService,
            writer: CancellingRecordsWriterStub(),
            syncMetadataStorage: storage,
            pageSize: 100
        )

        let result = await Task {
            try await sut.syncDelta()
        }.result

        #expect(throws: CancellationError.self) {
            try result.get()
        }
        #expect(networkService.requestedHistoryDeltaCursors == ["delta-0"])
        #expect(storage.deltaCursorValue == "delta-1")
    }

    @Test("A failed archive request stops the sync without finishing it")
    func failedArchiveRequestStopsSync() async {
        let networkService = JointAccountsNetworkServiceStub(historyPages: [
            Self.page(ids: ["op-1"], nextCursor: "archive-1", startDeltaCursor: "delta-0", hasMore: true),
        ])
        let (sut, _, storage) = makeSUT(networkService: networkService)

        await #expect(throws: (any Error).self) {
            try await sut.syncInitial()
        }

        #expect(storage.archiveCursorValue == "archive-1")
        #expect(!storage.isInitialSyncDoneValue)
    }

    @Test("The delta is paged through from the stored cursor, and a missing cursor is stored as such")
    func deltaIsPagedThroughStoringEveryCursor() async throws {
        let networkService = JointAccountsNetworkServiceStub(historyDeltaPages: [
            Self.page(ids: ["op-3"], nextCursor: "delta-1", startDeltaCursor: nil, hasMore: true),
            Self.page(ids: [], nextCursor: nil, startDeltaCursor: nil, hasMore: false),
        ])
        let (sut, writer, storage) = makeSUT(
            networkService: networkService,
            storage: JointOperationsSyncMetadataStorageStub(archiveCursor: nil, deltaCursor: "delta-0")
        )

        try await sut.syncDelta()

        #expect(networkService.requestedHistoryDeltaCursors == ["delta-0", "delta-1"])
        #expect(writer.savedRemoteOperationIds == [["op-3"], []])
        #expect(storage.deltaCursorValue == nil)
    }

    @Test("A delta page that fails to save leaves the delta cursor as it was")
    func failedDeltaSaveLeavesCursorUnchanged() async {
        let networkService = JointAccountsNetworkServiceStub(historyDeltaPages: [
            Self.page(ids: ["op-3"], nextCursor: "delta-1", startDeltaCursor: nil, hasMore: false),
        ])
        let (sut, _, storage) = makeSUT(
            networkService: networkService,
            writer: JointOperationsHistoryWriterStub(isFailing: true),
            storage: JointOperationsSyncMetadataStorageStub(archiveCursor: nil, deltaCursor: "delta-0")
        )

        await #expect(throws: (any Error).self) {
            try await sut.syncDelta()
        }

        #expect(storage.deltaCursorValue == "delta-0")
    }
}

// MARK: - Helpers

private extension CommonJointOperationsHistoryNetworkServiceTests {
    func makeSUT(
        networkService: JointAccountsNetworkServiceStub,
        writer: JointOperationsHistoryWriterStub = JointOperationsHistoryWriterStub(isFailing: false),
        storage: JointOperationsSyncMetadataStorageStub = JointOperationsSyncMetadataStorageStub(archiveCursor: nil, deltaCursor: nil)
    ) -> (CommonJointOperationsHistoryNetworkService, JointOperationsHistoryWriterStub, JointOperationsSyncMetadataStorageStub) {
        let sut = CommonJointOperationsHistoryNetworkService(
            networkService: networkService,
            writer: writer,
            syncMetadataStorage: storage,
            pageSize: 100
        )

        return (sut, writer, storage)
    }

    static func page(ids: [String], nextCursor: String?, startDeltaCursor: String?, hasMore: Bool) -> JointOperationsHistoryPage {
        JointOperationsHistoryPage(
            items: ids.map { JointOperationHistoryTestDataFactory.coinItem(id: $0) },
            nextCursor: nextCursor,
            startDeltaCursor: startDeltaCursor,
            hasMore: hasMore
        )
    }
}

// MARK: - Stubs

private struct CancellingRecordsWriterStub: JointOperationsHistoryWriter {
    func save(remote items: [JointOperationHistoryItem]) async throws {
        withUnsafeCurrentTask { $0?.cancel() }
    }

    func save(local items: [JointOperationHistoryItem]) async throws {}

    func delete(operationIds: [String]) async throws {}
}
