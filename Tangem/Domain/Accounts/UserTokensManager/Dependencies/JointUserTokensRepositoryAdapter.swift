//
//  JointUserTokensRepositoryAdapter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// The plain adapter for a joint account, with two things on top: the tokens live at an address that arrives only on
/// activation, and the record that carries it is read apart from the list.
final class JointUserTokensRepositoryAdapter {
    private let innerAdapter: any UserTokensRepository
    private let jointAccountsRepository: JointAccountsRepository
    private let safeAddressProvider: JointAccountSafeAddressProvider

    init(
        innerAdapter: any UserTokensRepository,
        jointAccountsRepository: JointAccountsRepository,
        safeAddressProvider: JointAccountSafeAddressProvider
    ) {
        self.innerAdapter = innerAdapter
        self.jointAccountsRepository = jointAccountsRepository
        self.safeAddressProvider = safeAddressProvider
    }

    private func loadCryptoAccountsFromRemote() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            innerAdapter.updateLocalRepositoryFromServer { result in
                continuation.resume(with: result)
            }
        }
    }
}

// MARK: - UserTokensRepository protocol conformance

extension JointUserTokensRepositoryAdapter: UserTokensRepository {
    /// - Note: Re-emits the account when its address arrives: the wallet managers are built out of this stream, and
    /// there is nothing to build them around until then.
    var cryptoAccountPublisher: AnyPublisher<StoredCryptoAccount, Never> {
        innerAdapter
            .cryptoAccountPublisher
            .combineLatest(safeAddressProvider.safeAddressPublisher)
            .map(\.0)
            .eraseToAnyPublisher()
    }

    var cryptoAccount: StoredCryptoAccount {
        innerAdapter.cryptoAccount
    }

    func performBatchUpdates(_ batchUpdates: BatchUpdates) rethrows {
        try innerAdapter.performBatchUpdates(batchUpdates)
    }

    /// Also reloads the record, so that a refresh brings the status and members round too.
    func updateLocalRepositoryFromServer(_ completion: @escaping Completion) {
        // Not `runTask(in:)`: that drops the body once `self` is gone, and the caller waits for the completion
        runTask { [weak self] in
            guard let self else {
                await runOnMain { completion(.failure(CancellationError())) }
                return
            }

            do {
                async let listLoad: Void = loadCryptoAccountsFromRemote()
                async let recordLoad: Void = jointAccountsRepository.loadJointAccountsFromRemote()
                _ = try await (listLoad, recordLoad)

                await runOnMain { completion(.success(())) }
            } catch {
                await runOnMain { completion(.failure(error)) }
            }
        }
    }
}
