//
//  CommonYieldModuleAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import BlockchainSdk

final class CommonYieldModuleAvailabilityProvider {
    private var isFeatureToggleEnabled: Bool { FeatureProvider.isAvailable(.yieldModule) }

    init() {}
}

extension CommonYieldModuleAvailabilityProvider: YieldModuleAvailabilityProvider {
    func isYieldModuleAvailable(for tokenItem: TokenItem) -> Bool {
        tokenItem.blockchain.isEvm && isFeatureToggleEnabled
    }
}
