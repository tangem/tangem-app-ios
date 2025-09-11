//
//  YieldModuleAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// YieldModule feature availability for a particular wallet.
protocol YieldModuleAvailabilityProvider {
    func isYieldModuleAvailable() -> Bool
}
