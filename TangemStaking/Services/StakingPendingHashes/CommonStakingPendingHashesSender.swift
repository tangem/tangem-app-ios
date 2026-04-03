//
//  CommonStakingPendingHashesSender.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class CommonStakingPendingHashesSender: StakingPendingHashesSender {
    let repository: StakingPendingHashesRepository
    let provider: StakeKitAPIProvider

    init(
        repository: StakingPendingHashesRepository,
        provider: StakeKitAPIProvider
    ) {
        self.repository = repository
        self.provider = provider
    }

    func sendHash(_ pendingHash: StakingPendingHash) async throws {
        repository.storeHash(pendingHash)
        try await provider.submitHash(hash: pendingHash.hash, transactionId: pendingHash.transactionId)
        repository.removeHash(pendingHash)
    }

    func sendHashesIfNeeded() {
        Task { [repository, provider] in
            let pendingHashes = repository.fetchHashes()
            guard !pendingHashes.isEmpty else { return }

            for pendingHash in pendingHashes {
                do {
                    try await provider.submitHash(hash: pendingHash.hash, transactionId: pendingHash.transactionId)
                    repository.removeHash(pendingHash)
                } catch {
                    if error.isNotFoundHTTPError {
                        repository.removeHash(pendingHash)
                    }
                }
            }
        }
    }
}

private extension Error {
    var isNotFoundHTTPError: Bool {
        if case .badStatusCode(let code, _, _) = self as? StakeKitHTTPError {
            return code == 404
        }
        return false
    }
}
