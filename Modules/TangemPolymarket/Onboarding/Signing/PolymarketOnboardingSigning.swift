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
        fastTradingAuthorization: PolymarketRelayedBatch.Unsigned?
    ) async throws(PolymarketSigningError) -> PolymarketOnboardingSignatures
}

public extension PolymarketOnboardingSigning {
    func sign(
        approvals: PolymarketRelayedBatch.Unsigned
    ) async throws(PolymarketSigningError) -> PolymarketOnboardingSignatures {
        try await sign(approvals: approvals, fastTradingAuthorization: nil)
    }
}

public struct PolymarketOnboardingSignatures {
    public let authHeaders: PolymarketCLOBAuthHeaders
    public let approvals: PolymarketRelayedBatch
    public let fastTradingAuthorization: PolymarketRelayedBatch?

    public init(
        authHeaders: PolymarketCLOBAuthHeaders,
        approvals: PolymarketRelayedBatch,
        fastTradingAuthorization: PolymarketRelayedBatch? = nil
    ) {
        self.authHeaders = authHeaders
        self.approvals = approvals
        self.fastTradingAuthorization = fastTradingAuthorization
    }
}
