//
//  CommonJointOperationsHistoryNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

final class CommonJointOperationsHistoryNetworkService {
    private let networkService: JointAccountsNetworkService
    private let writer: JointOperationsHistoryWriter
    private let syncMetadataStorage: JointOperationsSyncMetadataStorage
    private let pageSize: Int

    init(
        networkService: JointAccountsNetworkService,
        writer: JointOperationsHistoryWriter,
        syncMetadataStorage: JointOperationsSyncMetadataStorage,
        pageSize: Int
    ) {
        self.networkService = networkService
        self.writer = writer
        self.syncMetadataStorage = syncMetadataStorage
        self.pageSize = pageSize
    }
}

// MARK: - JointOperationsHistoryNetworkService protocol conformance

extension CommonJointOperationsHistoryNetworkService: JointOperationsHistoryNetworkService {
    func syncInitial() async throws {
        var cursor = try await syncMetadataStorage.archiveCursor()

        while !Task.isCancelled {
            let page = try await networkService.getOperationsHistory(afterCursor: cursor, limit: pageSize)

            TransactionHistoryLogger.debug(self, "Fetched archive page: \(page.items.count) operation(s), hasMore: \(page.hasMore)")

            try await writer.save(remote: page.items)

            let isFirstPage = cursor == nil
            if isFirstPage {
                try await syncMetadataStorage.setDeltaCursor(page.startDeltaCursor)
            }

            try await syncMetadataStorage.setArchiveCursor(page.nextCursor)

            guard page.hasMore else {
                try await syncMetadataStorage.setIsInitialSyncDone(true)
                return
            }

            cursor = page.nextCursor
        }
        throw CancellationError()
    }

    func syncDelta() async throws {
        var cursor = try await syncMetadataStorage.deltaCursor()

        while !Task.isCancelled {
            let page = try await networkService.getOperationsHistoryDelta(beforeCursor: cursor, limit: pageSize)

            TransactionHistoryLogger.debug(self, "Fetched delta page: \(page.items.count) operation(s), hasMore: \(page.hasMore)")

            try await writer.save(remote: page.items)
            try await syncMetadataStorage.setDeltaCursor(page.nextCursor)

            guard page.hasMore else {
                return
            }

            cursor = page.nextCursor
        }
        throw CancellationError()
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension CommonJointOperationsHistoryNetworkService: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
