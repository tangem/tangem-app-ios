//
//  StakingRepository.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol StakingRepository {
    var enabledYieldsPuiblisher: AnyPublisher<[YieldInfo], Never> { get }

    func updateEnabledYields(withReload: Bool)
    func getYield(id: String) -> YieldInfo?
    func getYield(item: StakingTokenItem) -> YieldInfo?
}
