//
//  JointOperationsHistoryWriter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol JointOperationsHistoryWriter: Sendable {
    func save(remote items: [JointOperationHistoryItem]) async throws
    func save(local items: [JointOperationHistoryItem]) async throws
    func delete(operationIds: [String]) async throws
}
