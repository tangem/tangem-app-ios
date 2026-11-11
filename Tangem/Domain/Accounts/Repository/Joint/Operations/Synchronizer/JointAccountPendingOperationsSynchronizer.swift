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
    var pendingOperations: [JointAccountOperations] { get }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountOperations], Never> { get }

    func operationPublisher(id: String) -> AnyPublisher<JointAccountOperation?, Never>

    var checkpoint: JointAccountPendingOperationsCheckpoint { get async }

    func apply(_ update: JointAccountPendingOperationsUpdate) async throws

    func apply(
        refreshedOperation operation: JointAccountOperation,
        forCryptoAccountId cryptoAccountId: String,
        requestedAt checkpoint: JointAccountPendingOperationsCheckpoint
    ) async throws

    func apply(listing: [JointAccountOperations], requestedAt checkpoint: JointAccountPendingOperationsCheckpoint) async throws
}
