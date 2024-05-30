//
//  StakingRepository.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public protocol StakingRepository: Actor {
    func updateEnabledYields(withReload: Bool) async throws

    func getYield(id: String) async throws -> YieldInfo?
    func getYield(item: StakingTokenItem) async throws -> YieldInfo?
}
