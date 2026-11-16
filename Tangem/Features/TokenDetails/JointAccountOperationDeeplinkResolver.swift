//
//  JointAccountOperationDeeplinkResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct JointAccountOperationDeeplinkResolver {
    private let jointAccount: any JointAccountModel
    private let historyOperations: [JointAccountOperation]
    private let timeout: Duration

    init(
        jointAccount: any JointAccountModel,
        historyOperations: [JointAccountOperation],
        timeout: Duration
    ) {
        self.jointAccount = jointAccount
        self.historyOperations = historyOperations
        self.timeout = timeout
    }

    func resolve(operationId: String) async throws -> JointAccountPendingOperation {
        let provider = jointAccount.jointAccountPendingOperationsProvider

        do {
            return try await Task.run(withTimeout: timeout) {
                try await resolve(operationId: operationId, through: provider)
            }
        } catch is TaskTimeoutError {
            throw Error.timedOut
        } catch where isUnavailable(error) {
            JointAccountsLogger.warning("The joint operation is unavailable: \(error)")
            throw Error.operationIsUnavailable
        }
    }
}

// MARK: - Private

private extension JointAccountOperationDeeplinkResolver {
    func resolve(operationId: String, through provider: any JointAccountPendingOperationsProvider) async throws -> JointAccountPendingOperation {
        for source in Source.allCases {
            if let pendingOperation = try await pendingOperation(id: operationId, from: source, through: provider) {
                return pendingOperation
            }
        }

        throw Error.operationIsUnavailable
    }

    func pendingOperation(
        id operationId: String,
        from source: Source,
        through provider: any JointAccountPendingOperationsProvider
    ) async throws -> JointAccountPendingOperation? {
        switch source {
        case .store:
            try await provider.pendingOperationsPublisher.async().first { $0.id == operationId }
        case .history:
            if let operation = historyOperations.first(where: { $0.id == operationId }) {
                try await provider.pendingOperation(from: operation)
            } else {
                nil
            }
        case .network:
            try await provider.loadOperation(id: operationId)
        }
    }

    func isUnavailable(_ error: any Swift.Error) -> Bool {
        switch error {
        case JointOperationError.operationNotFound,
             JointOperationError.notAMember,
             JointAccountPendingOperationsProviderError.walletNotFound,
             CommonJointAccountPendingOperationsRepository.InternalError.featureUnavailable:
            true
        default:
            false
        }
    }
}

// MARK: - Auxiliary types

extension JointAccountOperationDeeplinkResolver {
    enum Error: Swift.Error {
        case operationIsUnavailable
        case timedOut
    }
}

private extension JointAccountOperationDeeplinkResolver {
    enum Source: CaseIterable {
        case store
        case history
        case network
    }
}
