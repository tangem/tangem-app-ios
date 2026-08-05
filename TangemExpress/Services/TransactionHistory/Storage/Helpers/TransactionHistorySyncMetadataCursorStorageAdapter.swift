//
//  TransactionHistorySyncMetadataCursorStorageAdapter.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Exposes a single cursor of the `TransactionHistorySyncMetadataStorage` as a `TransactionHistoryCursorStorage`.
struct TransactionHistorySyncMetadataCursorStorageAdapter {
    private let metadataStorage: TransactionHistorySyncMetadataStorage
    private let branch: ExpressBranch
    private let cursorKind: CursorKind

    init(
        metadataStorage: TransactionHistorySyncMetadataStorage,
        branch: ExpressBranch,
        cursorKind: CursorKind
    ) {
        self.metadataStorage = metadataStorage
        self.branch = branch
        self.cursorKind = cursorKind
    }
}

// MARK: - Nested types

extension TransactionHistorySyncMetadataCursorStorageAdapter {
    enum CursorKind {
        case initialSync
        case deltaSync
    }
}

// MARK: - TransactionHistoryCursorStorage protocol conformance

extension TransactionHistorySyncMetadataCursorStorageAdapter: TransactionHistoryCursorStorage {
    func cursor() async -> Any? {
        do {
            switch cursorKind {
            case .initialSync:
                return try await metadataStorage.initialSyncCursor(for: branch)
            case .deltaSync:
                return try await metadataStorage.deltaSyncCursor(for: branch)
            }
        } catch {
            TransactionHistoryLogger.error(self, "Failed to read cursor", error: error)

            return nil
        }
    }

    func setCursor(_ cursor: Any?) async {
        do {
            switch cursorKind {
            case .initialSync:
                try await metadataStorage.setInitialSyncCursor(cursor, for: branch)
            case .deltaSync:
                try await metadataStorage.setDeltaSyncCursor(cursor, for: branch)
            }
        } catch {
            TransactionHistoryLogger.error(self, "Failed to save cursor", error: error)
        }
    }
}

// MARK: - CustomStringConvertible protocol conformance

extension TransactionHistorySyncMetadataCursorStorageAdapter: CustomStringConvertible {
    var description: String {
        objectDescription(
            String(describing: Self.self),
            userInfo: [
                "branch": branch.rawValue,
                "cursorKind": cursorKind,
            ]
        )
    }
}
