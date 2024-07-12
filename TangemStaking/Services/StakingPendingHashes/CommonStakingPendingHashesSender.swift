//
//  CommonStakingPendingHashesSender.swift
//  TangemStaking
//
//  Created by Alexander Osokin on 12.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

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
                try await provider.submitHash(pendingHash.hash, for: pendingHash.transactionId)
                repository.removeHash(pendingHash)
            }
        }
    }
}
