//
//  CommonStakingRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemStaking

actor CommonStakingRepositoryProxy {
    private let repository: StakingRepository

    init() {
        let provider = StakingDependenciesFactory().makeStakingAPIProvider()
        repository = TangemStakingFactory().makeStakingRepository(provider: provider, logger: AppLog.shared)
    }
}

extension CommonStakingRepositoryProxy: StakingRepository {
    func updateEnabledYields(withReload: Bool) async throws {
        try await repository.updateEnabledYields(withReload: withReload)
    }

    func getYield(id: String) async throws -> YieldInfo? {
        try await repository.getYield(id: id)
    }

    func getYield(item: StakingTokenItem) async throws -> YieldInfo? {
        try await repository.getYield(item: item)
    }
}

extension CommonStakingRepositoryProxy: Initializable {
    nonisolated func initialize() {
        runTask(in: self, code: { repository in
            try await repository.updateEnabledYields(withReload: true)
        })
    }
}
