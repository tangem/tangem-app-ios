//
//  PolymarketAccountState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

@CaseFlagable
enum PolymarketAccountState: Equatable {
    case loading
    case onboarding(PolymarketOnboardingStage)
    case onboardingFailed(PolymarketOnboardingStage)
    case syncNeeded
    case active
    case unavailable
}

extension PolymarketAccountState {
    var isAccountVisible: Bool {
        switch self {
        case .active, .syncNeeded: true
        case .loading, .onboarding, .onboardingFailed, .unavailable: false
        }
    }
}
