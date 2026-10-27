//
//  CommonJointAccountPendingOperationsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

final class CommonJointAccountPendingOperationsRepository {
    private let networkService: JointAccountsNetworkService
    private let synchronizer: JointAccountPendingOperationsSynchronizer
    private let isJointAccountsAvailable: Bool

    private let pollingState = OSAllocatedUnfairLock(initialState: PollingState())
    private var pendingOperationsSubscription: AnyCancellable?

    init(
        networkService: JointAccountsNetworkService,
        synchronizer: JointAccountPendingOperationsSynchronizer,
        isJointAccountsAvailable: Bool
    ) {
        self.networkService = networkService
        self.synchronizer = synchronizer
        self.isJointAccountsAvailable = isJointAccountsAvailable

        if isJointAccountsAvailable {
            bind()
        }
    }
}

// MARK: - JointAccountPendingOperationsRepository protocol conformance

extension CommonJointAccountPendingOperationsRepository: JointAccountPendingOperationsRepository {
    var operations: [StoredJointAccountPendingOperations] {
        synchronizer.operations
    }

    var operationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> {
        synchronizer.operationsPublisher
    }

    func operationPublisher(id: String, in cryptoAccountId: String) -> AnyPublisher<JointAccountOperation, Never> {
        synchronizer.operationPublisher(id: id, in: cryptoAccountId)
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        let poller = pollingState.withLockUnchecked { $0.pollers[operationId] }

        return poller?.requestFrequentUpdates()
    }

    func createOperation(_ request: JointAccountOperationRequest, forCryptoAccountId cryptoAccountId: String) async throws -> JointAccountOperation {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let operation = try await networkService.createOperation(request)
        try await synchronizer.apply(.localOperation(operation, cryptoAccountId: cryptoAccountId))

        return operation
    }

    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data, forCryptoAccountId cryptoAccountId: String) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let operation = try await networkService.signOperation(id: id, safeTransaction: safeTransaction, signature: signature)
        try await synchronizer.apply(.localOperation(operation, cryptoAccountId: cryptoAccountId))
    }

    func rejectOperation(id: String, forCryptoAccountId cryptoAccountId: String) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        guard let operation = try await networkService.rejectOperation(id: id) else {
            try await synchronizer.apply(.operationRemoved(id: id, cryptoAccountId: cryptoAccountId))
            return
        }

        try await synchronizer.apply(.localOperation(operation, cryptoAccountId: cryptoAccountId))
    }
}

// MARK: - JointAccountPendingOperationPollerLoader protocol conformance

extension CommonJointAccountPendingOperationsRepository: JointAccountPendingOperationPollerLoader {
    func reloadPendingOperation(with operationId: String, in cryptoAccountId: String, knownETag: String?) async throws -> JointOperationFetchResult {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        guard isInFlight(operationWithId: operationId, in: cryptoAccountId) else {
            return .notModified
        }

        let checkpoint = await synchronizer.checkpoint

        do {
            let result = try await networkService.getOperation(id: operationId, knownETag: knownETag)

            if case .modified(let item, _) = result {
                try await synchronizer.apply(refreshedOperation: item.operation, forCryptoAccountId: cryptoAccountId, requestedAt: checkpoint)
            }

            return result
        } catch JointOperationError.operationNotFound, JointOperationError.notAMember {
            try await synchronizer.apply(.operationRemoved(id: operationId, cryptoAccountId: cryptoAccountId))
            return .notModified
        }
    }
}

// MARK: - Private

private extension CommonJointAccountPendingOperationsRepository {
    func bind() {
        pendingOperationsSubscription = synchronizer
            .operationsPublisher
            .withWeakCaptureOf(self)
            .sink { repository, records in
                repository.updatePollers(for: records)
            }
    }

    func updatePollers(for records: [StoredJointAccountPendingOperations]) {
        let inFlightRecords = inFlightRecords(in: records)
        let inFlightOperationIds = Set(inFlightRecords.flatMap { $0.operations.map(\.id) })

        pollingState.withLockUnchecked { state in
            state.pollers = state.pollers.filter { inFlightOperationIds.contains($0.key) }

            for record in inFlightRecords {
                for operation in record.operations where state.pollers[operation.id] == nil {
                    state.pollers[operation.id] = CommonJointAccountPendingOperationPoller(
                        cryptoAccountId: record.cryptoAccountId,
                        operationId: operation.id,
                        delegate: self
                    )
                }
            }
        }
    }

    func inFlightRecords(in records: [StoredJointAccountPendingOperations]) -> [StoredJointAccountPendingOperations] {
        records.compactMap { record in
            let operations = record.operations.filter(\.status.isInFlight)

            return operations.isEmpty ? nil : StoredJointAccountPendingOperations(cryptoAccountId: record.cryptoAccountId, operations: operations)
        }
    }

    func isInFlight(operationWithId operationId: String, in cryptoAccountId: String) -> Bool {
        let operations = synchronizer.operations.first(by: cryptoAccountId)?.operations
        return operations?.first { $0.id == operationId }?.status.isInFlight == true
    }
}

// MARK: - Auxiliary types

extension CommonJointAccountPendingOperationsRepository {
    enum InternalError: Error {
        case featureUnavailable
    }
}

private extension CommonJointAccountPendingOperationsRepository {
    struct PollingState {
        var pollers: [String: JointAccountPendingOperationPoller] = [:]
    }
}
