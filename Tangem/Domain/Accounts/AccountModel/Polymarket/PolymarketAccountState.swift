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
enum PolymarketAccountState {
    case loading
    case onboarding(PolymarketOnboardingStage)
    case onboardingFailed(PolymarketOnboardingStage)
    case syncNeeded
    case active(depositWalletAddress: String)
    case unavailable
}
