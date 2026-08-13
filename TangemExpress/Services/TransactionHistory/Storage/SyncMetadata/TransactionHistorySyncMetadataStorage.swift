//
//  TransactionHistorySyncMetadataStorage.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A storage for the opaque (hence `Any`) cursor for the next page and other metadata related to the transaction history sync.
public protocol TransactionHistorySyncMetadataStorage: Sendable {
    func initialSyncCursor(for branch: ExpressBranch) async throws -> Any?
    func setInitialSyncCursor(_ cursor: Any?, for branch: ExpressBranch) async throws

    func deltaSyncCursor(for branch: ExpressBranch) async throws -> Any?
    func setDeltaSyncCursor(_ cursor: Any?, for branch: ExpressBranch) async throws

    func isInitialSyncDone() async throws -> Bool
    func setIsInitialSyncDone(_ isDone: Bool) async throws

    func clear() async throws
}
