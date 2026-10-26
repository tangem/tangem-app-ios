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
    var pendingOperations: [StoredJointAccountPendingOperations] { get }

    var pendingOperationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> { get }

    var checkpoint: JointAccountPendingOperationsCheckpoint { get async }

    func apply(_ update: JointAccountPendingOperationsUpdate) async throws

    func apply(listing: [StoredJointAccountPendingOperations], requestedAt checkpoint: JointAccountPendingOperationsCheckpoint) async throws
}
