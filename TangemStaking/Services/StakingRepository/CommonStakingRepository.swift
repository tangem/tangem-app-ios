//
//  CommonStakingRepository.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

actor CommonStakingRepository {
    private let provider: StakingAPIProvider
    private let logger: Logger

    private var availableYields: [YieldInfo] = []
    private var wasAttemptToLoad = false

    init(provider: StakingAPIProvider, logger: Logger) {
        self.provider = provider
        self.logger = logger
    }
}

extension CommonStakingRepository: StakingRepository {
    func updateEnabledYields(withReload: Bool) async throws {
        guard withReload || !wasAttemptToLoad else {
            if wasAttemptToLoad {
                logger.debug("CommonStakingRepository has duplicate request to load the enabled yields")
            }
            return
        }

        wasAttemptToLoad = true
        availableYields = try await provider.enabledYields()
    }

    func getYield(id: String) async throws -> YieldInfo? {
        try await updateEnabledYields(withReload: false)
        return availableYields.first(where: { $0.id == id })
    }

    func getYield(item: StakingTokenItem) async throws -> YieldInfo? {
        try await updateEnabledYields(withReload: false)
        return availableYields.first(where: { $0.item == item })
    }
}
