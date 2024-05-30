//
//  CommonStakingManager.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

actor CommonStakingManager {
    private let provider: StakingAPIProvider
    private let repository: StakingRepository
    private let logger: Logger

    init(provider: StakingAPIProvider, repository: StakingRepository, logger: Logger) {
        self.provider = provider
        self.repository = repository
        self.logger = logger
    }
}

extension CommonStakingManager: StakingManager {
    func getYield(item: StakingTokenItem) async throws -> YieldInfo {
        guard let yield = try await repository.getYield(item: item) else {
            throw StakingManagerError.notFound
        }

        return yield
    }
}

public enum StakingManagerError: Error {
    case notFound
}
