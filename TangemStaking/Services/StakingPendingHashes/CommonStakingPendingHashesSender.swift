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
    let provider: StakingAPIProvider

    init(
        repository: StakingPendingHashesRepository,
        provider: StakingAPIProvider
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
        Task { [weak self] in
            guard let self else {
                return
            }

            let pendingHashes = repository.fetchHashes()
            guard !pendingHashes.isEmpty else {
                return
            }

            for pendingHash in pendingHashes {
                try await provider.submitHash(hash: pendingHash.hash, transactionId: pendingHash.transactionId)
                repository.removeHash(pendingHash)
            }
        }
    }
}
