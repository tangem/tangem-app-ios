//
//  CommonStakingAvailabilityProvider.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

actor CommonStakingAvailabilityProvider: StakingAvailabilityProvider {
    private let repository: StakingRepository

    init(repository: StakingRepository) {
        self.repository = repository
    }

    func isAvailableForStaking(item: StakingTokenItem) async throws -> Bool {
        try await repository.getYield(item: item) != nil
    }
}
