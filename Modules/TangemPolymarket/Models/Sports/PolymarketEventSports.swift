//
//  PolymarketEventSports.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketEventSports: Hashable, Sendable {
    public let isSports: Bool
    public let moneylineConditionIds: Set<String>

    public init(isSports: Bool, moneylineConditionIds: Set<String>) {
        self.isSports = isSports
        self.moneylineConditionIds = moneylineConditionIds
    }
}
