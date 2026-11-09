//
//  JointAccountPendingOperationHandle.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// What this member does about an unfinished operation of the account, and what a screen follows it through as the
/// store changes it.
struct JointAccountPendingOperationHandle: Equatable {
    let id: String
    let wallet: JointAccountWallet
    @IgnoredEquatable
    var pendingOperationPublisher: AnyPublisher<JointAccountPendingOperation?, Never>

    init(id: String, wallet: JointAccountWallet, pendingOperationPublisher: AnyPublisher<JointAccountPendingOperation?, Never>) {
        self.id = id
        self.wallet = wallet
        self.pendingOperationPublisher = pendingOperationPublisher
    }
}

// MARK: - Actions

extension JointAccountPendingOperationHandle {
    /// Counts this member's signature towards the threshold.
    func sign(_ pendingOperation: JointAccountPendingOperation) async throws -> JointAccountOperation {
        guard pendingOperation.id == id else {
            throw JointOperationError.operationMismatch
        }

        return try await pendingOperation.wallet.sign(pendingOperation.operation)
    }

    /// Declines the operation, which the initiator's own answer ends outright.
    func reject() async throws {
        try await wallet.reject(operationId: id)
    }
}

// MARK: - JointAccountPendingOperationPoller protocol conformance

extension JointAccountPendingOperationHandle: JointAccountPendingOperationPoller {
    func requestFrequentUpdates() -> AnyCancellable? {
        wallet.account?.jointAccountPendingOperationsProvider.requestFrequentUpdates(operationId: id)
    }
}
