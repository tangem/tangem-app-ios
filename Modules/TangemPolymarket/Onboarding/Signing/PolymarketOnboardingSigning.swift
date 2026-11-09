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
        approvals: PolymarketRelayedBatch.Unsigned,
        followUps: [PolymarketRelayedBatch.Unsigned]
    ) async throws(PolymarketSigningError) -> PolymarketOnboardingSignatures
}

public extension PolymarketOnboardingSigning {
    func sign(
        approvals: PolymarketRelayedBatch.Unsigned
    ) async throws(PolymarketSigningError) -> PolymarketOnboardingSignatures {
        try await sign(approvals: approvals, followUps: [])
    }
}

public struct PolymarketOnboardingSignatures {
    public let authHeaders: PolymarketCLOBAuthHeaders
    public let approvals: PolymarketRelayedBatch
    public let followUps: [PolymarketRelayedBatch]

    public init(authHeaders: PolymarketCLOBAuthHeaders, approvals: PolymarketRelayedBatch, followUps: [PolymarketRelayedBatch] = []) {
        self.authHeaders = authHeaders
        self.approvals = approvals
        self.followUps = followUps
    }
}
