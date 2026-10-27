//
//  JointAccountPendingOperationsSynchronizer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol JointAccountPendingOperationsSynchronizer {
    var operations: [StoredJointAccountPendingOperations] { get }

    var operationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> { get }

    var checkpoint: JointAccountPendingOperationsCheckpoint { get async }

    func apply(_ update: JointAccountPendingOperationsUpdate) async throws

    func apply(
        refreshedOperation operation: JointAccountOperation,
        forCryptoAccountId cryptoAccountId: String,
        requestedAt checkpoint: JointAccountPendingOperationsCheckpoint
    ) async throws

    func apply(listing: [StoredJointAccountPendingOperations], requestedAt checkpoint: JointAccountPendingOperationsCheckpoint) async throws
}

// MARK: - Single operation

extension JointAccountPendingOperationsSynchronizer {
    /// The stored operation with that identifier under that account: emitted at once when it is stored, and again on
    /// every change the store makes to it.
    /// - Note: Goes on past the operation finishing, so whoever shows it sees how it ended; once the store drops the
    /// operation it falls silent without completing.
    func operationPublisher(id operationId: String, in cryptoAccountId: String) -> AnyPublisher<JointAccountOperation, Never> {
        operationsPublisher
            .compactMap { $0.first(by: cryptoAccountId)?.operations.first { $0.id == operationId } }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
