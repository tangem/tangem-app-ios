//
//  JointAccountsPendingOperationsPersistentStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// - Note: Separate from `JointAccountsPersistentStorage` because an operation moves on its own occasions — a
/// co-signer answers, the relayer executes — and none of them is a change to the account it belongs to.
protocol JointAccountsPendingOperationsPersistentStorage {
    var didUpdatePublisher: AnyPublisher<Void, Never> { get }

    func inFlightOperations(safeAddresses: Set<String>) throws -> [JointOperationHistoryItem]

    func operation(id: String) throws -> JointOperationHistoryItem?

    func update(
        operationIds: Set<String>,
        safeAddresses: Set<String>,
        _ resolveChanges: ([JointOperationHistoryItem]) -> JointAccountsPendingOperationsChanges
    ) throws
}

struct JointAccountsPendingOperationsChanges: Equatable {
    let savedItems: [JointOperationHistoryItem]
    let removedOperationIds: [String]

    var isEmpty: Bool {
        savedItems.isEmpty && removedOperationIds.isEmpty
    }
}
