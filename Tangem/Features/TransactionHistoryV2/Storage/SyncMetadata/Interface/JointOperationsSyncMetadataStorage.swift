//
//  JointOperationsSyncMetadataStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol JointOperationsSyncMetadataStorage: Sendable {
    func archiveCursor() async throws -> String?
    func setArchiveCursor(_ cursor: String?) async throws
    func deltaCursor() async throws -> String?
    func setDeltaCursor(_ cursor: String?) async throws
    func isInitialSyncDone() async throws -> Bool
    func setIsInitialSyncDone(_ isDone: Bool) async throws
    func clear() async throws
}
