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
