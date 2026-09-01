//
//  PolymarketOnboardingSigning.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketOnboardingSigning {
    func sign(
        approvals: PolymarketApprovalsBatch.Unsigned
    ) async throws(PolymarketSigningError) -> PolymarketOnboardingSignatures
}

struct PolymarketOnboardingSignatures {
    let authHeaders: PolymarketCLOBAuthHeaders
    let approvals: PolymarketApprovalsBatch
}
