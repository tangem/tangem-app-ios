//
//  PolymarketOnboardingSigning.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketOnboardingSigning {
    func sign(
        approvals: PolymarketApprovalsBatch.Unsigned
    ) async throws(PolymarketSigningError) -> PolymarketOnboardingSignatures
}

public struct PolymarketOnboardingSignatures {
    public let authHeaders: PolymarketCLOBAuthHeaders
    public let approvals: PolymarketApprovalsBatch

    public init(authHeaders: PolymarketCLOBAuthHeaders, approvals: PolymarketApprovalsBatch) {
        self.authHeaders = authHeaders
        self.approvals = approvals
    }
}
